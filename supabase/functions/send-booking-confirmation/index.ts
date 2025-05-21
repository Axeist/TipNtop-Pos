
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

interface BookingConfirmationRequest {
  bookingId: string
  customerName: string
  stationName: string
  bookingDate: string
  startTime: string
  endTime: string
  duration: number
  bookingReference: string
  recipientEmail: string
  discount?: string
  finalPrice?: string
  totalStations?: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  
  try {
    console.log('Received request to send booking confirmation email');
    
    // Parse and validate the request body
    let requestBody;
    try {
      requestBody = await req.json();
      console.log('Request body:', JSON.stringify(requestBody));
    } catch (parseError) {
      console.error('Error parsing request JSON:', parseError);
      throw new Error('Invalid JSON request body');
    }
    
    // Validate essential fields
    const { 
      bookingId, 
      customerName, 
      stationName, 
      bookingDate, 
      startTime, 
      endTime, 
      duration, 
      bookingReference,
      recipientEmail,
      discount,
      finalPrice,
      totalStations
    } = requestBody as BookingConfirmationRequest;

    // Validate required fields
    if (!recipientEmail) {
      console.error('No recipient email provided');
      throw new Error('No recipient email provided');
    }
    
    if (!customerName || !stationName || !bookingDate || !startTime || !endTime) {
      console.error('Missing required booking information');
      throw new Error('Missing required booking information for email');
    }

    // Check for API key
    if (!RESEND_API_KEY) {
      console.error('RESEND_API_KEY is not set in environment variables');
      throw new Error('Email API key not configured');
    }
    
    console.log(`Preparing to send email to: ${recipientEmail}`);

    // Prepare the email content
    const emailContent = `
      <html>
        <head>
          <style>
            body { 
              font-family: Arial, sans-serif; 
              line-height: 1.6;
              color: #333;
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
            }
            .header { 
              background: linear-gradient(to right, #6a11cb, #8e44ad);
              color: white;
              padding: 20px;
              text-align: center;
              border-radius: 5px 5px 0 0;
            }
            .content {
              background-color: #f9f9f9;
              padding: 20px;
              border-radius: 0 0 5px 5px;
              border: 1px solid #eee;
            }
            .booking-info {
              background-color: white;
              padding: 15px;
              border-radius: 5px;
              margin-bottom: 20px;
              border: 1px solid #eee;
            }
            .reference {
              font-family: monospace;
              font-size: 18px;
              font-weight: bold;
              color: #6a11cb;
              letter-spacing: 1px;
              text-align: center;
              padding: 10px;
              border: 1px dashed #8e44ad;
              border-radius: 4px;
              background-color: #f0f0f0;
            }
            .footer {
              text-align: center;
              font-size: 12px;
              color: #777;
              margin-top: 30px;
            }
            .cta-button {
              display: inline-block;
              background: linear-gradient(to right, #6a11cb, #8e44ad);
              color: white !important;
              text-decoration: none;
              padding: 10px 20px;
              border-radius: 5px;
              margin-top: 15px;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>Booking Confirmation</h1>
          </div>
          <div class="content">
            <p>Hello ${customerName},</p>
            <p>Thank you for booking with Cuephoria! Your reservation has been confirmed.</p>
            
            <div class="booking-info">
              <h3>Booking Details:</h3>
              <p><strong>Station:</strong> ${stationName}</p>
              <p><strong>Date:</strong> ${bookingDate}</p>
              <p><strong>Time:</strong> ${startTime} - ${endTime}</p>
              <p><strong>Duration:</strong> ${duration} minutes</p>
              ${totalStations && totalStations > 1 ? `<p><strong>Total Stations:</strong> ${totalStations}</p>` : ''}
              ${discount ? `<p><strong>Discount:</strong> ${discount}</p>` : ''}
              ${finalPrice ? `<p><strong>Final Price:</strong> ₹${finalPrice}</p>` : ''}
              
              <h3>Booking Reference:</h3>
              <div class="reference">${bookingReference}</div>
              <p style="text-align:center; font-size:12px; margin-top:5px;">Please present this reference when you arrive</p>
            </div>
            
            <p>We're looking forward to welcoming you to Cuephoria!</p>
            <p>If you need to make any changes to your booking, please contact us.</p>
            
            <div style="text-align:center">
              <a href="https://admin.cuephoria.in/booknow" class="cta-button">Book Another Session</a>
            </div>
          </div>
          <div class="footer">
            <p>&copy; ${new Date().getFullYear()} Cuephoria. All rights reserved.</p>
          </div>
        </body>
      </html>
    `;

    // Log email attempt
    console.log(`Sending email to ${recipientEmail} via Resend API`);

    try {
      // Send email using Resend API
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`
        },
        body: JSON.stringify({
          from: 'Cuephoria Booking <bookings@cuephoria.in>',
          to: recipientEmail,
          subject: `Booking Confirmation - ${bookingReference}`,
          html: emailContent,
        })
      });

      if (!response.ok) {
        const errorDetails = await response.text();
        console.error(`Resend API error: ${response.status} ${response.statusText}`, errorDetails);
        throw new Error(`Email API responded with error: ${response.status} ${response.statusText}`);
      }

      const responseData = await response.json();
      console.log('Resend API response:', JSON.stringify(responseData));

      return new Response(
        JSON.stringify({ success: true, data: responseData }),
        { 
          status: 200, 
          headers: { 
            ...corsHeaders,
            'Content-Type': 'application/json' 
          }
        }
      );
    } catch (fetchError) {
      console.error('Error calling Resend API:', fetchError);
      throw new Error(`Error sending email: ${fetchError.message}`);
    }
  } catch (error) {
    console.error('Error sending booking confirmation:', error);
    
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { 
        status: 400, 
        headers: { 
          ...corsHeaders,
          'Content-Type': 'application/json' 
        }
      }
    );
  }
});
