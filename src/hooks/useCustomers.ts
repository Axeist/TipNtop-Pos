import { useState, useEffect } from 'react';
import { Customer } from '@/types/pos.types';
import { supabase } from "@/integrations/supabase/client";
import { useToast } from '@/hooks/use-toast';

export const useCustomers = (initialCustomers: Customer[]) => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const { toast } = useToast();
  
  useEffect(() => {
    const fetchCustomers = async () => {
      try {
        const storedCustomers = localStorage.getItem('cuephoriaCustomers');
        if (storedCustomers) {
          const parsedCustomers = JSON.parse(storedCustomers);
          
          const customersWithDates = parsedCustomers.map((customer: any) => ({
            ...customer,
            createdAt: new Date(customer.createdAt),
            membershipStartDate: customer.membershipStartDate ? new Date(customer.membershipStartDate) : undefined,
            membershipExpiryDate: customer.membershipExpiryDate ? new Date(customer.membershipExpiryDate) : undefined,
            totalPlayTime: typeof customer.totalPlayTime === 'number' ? customer.totalPlayTime : 0 // Ensure totalPlayTime is a number
          }));
          
          setCustomers(customersWithDates);
          
          for (const customer of customersWithDates) {
            await supabase.from('customers').upsert({
                id: customer.id,
                name: customer.name,
                phone: customer.phone,
                email: customer.email,
                is_member: customer.isMember,
                membership_expiry_date: customer.membershipExpiryDate?.toISOString(),
                membership_start_date: customer.membershipStartDate?.toISOString(),
                membership_plan: customer.membershipPlan,
                membership_hours_left: customer.membershipHoursLeft,
                membership_duration: customer.membershipDuration,
                loyalty_points: customer.loyaltyPoints,
                total_spent: customer.totalSpent,
                total_play_time: customer.totalPlayTime, // Ensure this is a number
                created_at: customer.createdAt.toISOString()
              }, 
              { onConflict: 'id' }
            );
          }
          
          localStorage.removeItem('cuephoriaCustomers');
          return;
        }
        
        const { data, error } = await supabase
          .from('customers')
          .select('*');
          
        if (error) {
          console.error('Error fetching customers:', error);
          toast({
            title: 'Database Error',
            description: 'Failed to fetch customers from database',
            variant: 'destructive'
          });
          return;
        }
        
        if (data && data.length > 0) {
          const transformedCustomers = data.map(item => {
            // Log each customer's play time as we load it
            console.log(`Loading customer ${item.name}, database totalPlayTime:`, item.total_play_time);
            
            return {
              id: item.id,
              name: item.name,
              phone: item.phone,
              email: item.email || undefined,
              isMember: item.is_member,
              membershipExpiryDate: item.membership_expiry_date ? new Date(item.membership_expiry_date) : undefined,
              membershipStartDate: item.membership_start_date ? new Date(item.membership_start_date) : undefined,
              membershipPlan: item.membership_plan || undefined,
              membershipHoursLeft: item.membership_hours_left || undefined,
              membershipDuration: item.membership_duration as 'weekly' | 'monthly' | undefined,
              loyaltyPoints: item.loyalty_points,
              totalSpent: item.total_spent,
              totalPlayTime: typeof item.total_play_time === 'number' ? item.total_play_time : 0, // Ensure this is always a number
              createdAt: new Date(item.created_at)
            };
          });
          
          setCustomers(transformedCustomers);
        } else {
          setCustomers([]);
        }
      } catch (error) {
        console.error('Error in fetchCustomers:', error);
        toast({
          title: 'Error',
          description: 'Failed to load customers',
          variant: 'destructive'
        });
        setCustomers([]);
      }
    };
    
    fetchCustomers();
  }, []);
  
  useEffect(() => {
    const now = new Date();
    let customersUpdated = false;
    
    const checkExpirations = async () => {
      const updatedCustomers = customers.map(customer => {
        if (customer.isMember && customer.membershipExpiryDate) {
          const expiryDate = new Date(customer.membershipExpiryDate);
          
          if (expiryDate < now) {
            customersUpdated = true;
            console.log(`Membership expired for ${customer.name}`);
            return {
              ...customer,
              isMember: false
            };
          }
        }
        return customer;
      });
      
      if (customersUpdated) {
        setCustomers(updatedCustomers);
        
        for (const customer of updatedCustomers) {
          if (!customer.isMember) {
            await supabase
              .from('customers')
              .update({ is_member: false })
              .eq('id', customer.id);
          }
        }
      }
    };
    
    checkExpirations();
  }, [customers]);
  
  const isDuplicateCustomer = (phone: string, email?: string): { isDuplicate: boolean, existingCustomer?: Customer } => {
    const existingByPhone = customers.find(c => c.phone === phone);
    if (existingByPhone) {
      return { isDuplicate: true, existingCustomer: existingByPhone };
    }
    
    if (email) {
      const existingByEmail = customers.find(c => c.email === email);
      if (existingByEmail) {
        return { isDuplicate: true, existingCustomer: existingByEmail };
      }
    }
    
    return { isDuplicate: false };
  };
  
  const addCustomer = async (customer: Omit<Customer, 'id' | 'createdAt'>) => {
    try {
      const { isDuplicate, existingCustomer } = isDuplicateCustomer(customer.phone, customer.email);
      
      if (isDuplicate && existingCustomer) {
        toast({
          title: 'Duplicate Customer',
          description: `A customer with this ${existingCustomer.phone === customer.phone ? 'phone number' : 'email'} already exists.`,
          variant: 'destructive'
        });
        return existingCustomer;
      }
      
      const { data, error } = await supabase
        .from('customers')
        .insert({
          name: customer.name,
          phone: customer.phone,
          email: customer.email,
          is_member: customer.isMember,
          membership_expiry_date: customer.membershipExpiryDate?.toISOString(),
          membership_start_date: customer.membershipStartDate?.toISOString(),
          membership_plan: customer.membershipPlan,
          membership_hours_left: customer.membershipHoursLeft,
          membership_duration: customer.membershipDuration,
          loyalty_points: customer.loyaltyPoints || 0,
          total_spent: customer.totalSpent || 0,
          total_play_time: customer.totalPlayTime || 0
        })
        .select()
        .single();
        
      if (error) {
        console.error('Error adding customer:', error);
        toast({
          title: 'Database Error',
          description: 'Failed to add customer to database',
          variant: 'destructive'
        });
        return null;
      }
      
      if (data) {
        const newCustomer: Customer = {
          id: data.id,
          name: data.name,
          phone: data.phone,
          email: data.email || undefined,
          isMember: data.is_member,
          membershipExpiryDate: data.membership_expiry_date ? new Date(data.membership_expiry_date) : undefined,
          membershipStartDate: data.membership_start_date ? new Date(data.membership_start_date) : undefined,
          membershipPlan: data.membership_plan || undefined,
          membershipHoursLeft: data.membership_hours_left || undefined,
          membershipDuration: data.membership_duration as 'weekly' | 'monthly' | undefined,
          loyaltyPoints: data.loyalty_points,
          totalSpent: data.total_spent,
          totalPlayTime: data.total_play_time,
          createdAt: new Date(data.created_at)
        };
        
        setCustomers(prev => [...prev, newCustomer]);
        
        toast({
          title: 'Success',
          description: 'Customer added successfully',
        });
        
        return newCustomer;
      }
      return null;
    } catch (error) {
      console.error('Error in addCustomer:', error);
      toast({
        title: 'Error',
        description: 'Failed to add customer',
        variant: 'destructive'
      });
      return null;
    }
  };
  
  const updateCustomerMembership = async (customerId: string, membershipData: {
    membershipPlan?: string;
    membershipDuration?: 'weekly' | 'monthly';
    membershipHoursLeft?: number;
  }) => {
    const customer = customers.find(c => c.id === customerId);
    if (!customer) return null;
    
    const now = new Date();
    const membershipStartDate = now;
    let membershipExpiryDate = new Date(now);
    
    if (membershipData.membershipDuration === 'weekly') {
      membershipExpiryDate.setDate(membershipExpiryDate.getDate() + 7);
    } else if (membershipData.membershipDuration === 'monthly') {
      membershipExpiryDate.setMonth(membershipExpiryDate.getMonth() + 1);
    }
    
    const updatedCustomer = {
      ...customer,
      isMember: true,
      membershipPlan: membershipData.membershipPlan || customer.membershipPlan,
      membershipDuration: membershipData.membershipDuration || customer.membershipDuration,
      membershipHoursLeft: membershipData.membershipHoursLeft !== undefined 
        ? membershipData.membershipHoursLeft 
        : customer.membershipHoursLeft,
      membershipStartDate,
      membershipExpiryDate
    };
    
    const result = await updateCustomer(updatedCustomer);
    
    toast({
      title: "Membership Updated",
      description: `${customer.name}'s membership has been updated successfully.`,
      variant: "default"
    });
    
    return result;
  };
  
  const updateCustomer = async (customer: Customer) => {
    try {
      const existingCustomer = customers.find(c => c.id === customer.id);
      
      if (existingCustomer) {
        if (existingCustomer.phone !== customer.phone) {
          const duplicatePhone = customers.find(c => c.id !== customer.id && c.phone === customer.phone);
          if (duplicatePhone) {
            toast({
              title: 'Duplicate Phone Number',
              description: 'This phone number is already used by another customer',
              variant: 'destructive'
            });
            return null;
          }
        }
        
        if (existingCustomer.email !== customer.email && customer.email) {
          const duplicateEmail = customers.find(c => c.id !== customer.id && c.email === customer.email);
          if (duplicateEmail) {
            toast({
              title: 'Duplicate Email',
              description: 'This email is already used by another customer',
              variant: 'destructive'
            });
            return null;
          }
        }
      }
      
      // Ensure totalPlayTime is always a number and log it for debugging
      const safePlayTime = typeof customer.totalPlayTime === 'number' ? customer.totalPlayTime : 0;
      
      // Create an updated customer with safe values
      const updatedCustomer = {
        ...customer,
        totalPlayTime: safePlayTime
      };
      
      console.log(`Updating customer in database:`, { 
        id: customer.id,
        name: customer.name,
        totalPlayTime: {
          original: customer.totalPlayTime,
          type: typeof customer.totalPlayTime,
          safeValue: safePlayTime
        }
      });
      
      const { error } = await supabase
        .from('customers')
        .update({
          name: updatedCustomer.name,
          phone: updatedCustomer.phone,
          email: updatedCustomer.email,
          is_member: updatedCustomer.isMember,
          membership_expiry_date: updatedCustomer.membershipExpiryDate?.toISOString(),
          membership_start_date: updatedCustomer.membershipStartDate?.toISOString(),
          membership_plan: updatedCustomer.membershipPlan,
          membership_hours_left: updatedCustomer.membershipHoursLeft,
          membership_duration: updatedCustomer.membershipDuration,
          loyalty_points: updatedCustomer.loyaltyPoints,
          total_spent: updatedCustomer.totalSpent,
          total_play_time: safePlayTime
        })
        .eq('id', updatedCustomer.id);
        
      if (error) {
        console.error('Error updating customer:', error);
        toast({
          title: 'Database Error',
          description: 'Failed to update customer in database',
          variant: 'destructive'
        });
        return null;
      }
      
      // Update local state after successful database update
      setCustomers(customers.map(c => 
        c.id === updatedCustomer.id ? updatedCustomer : c
      ));
      
      if (selectedCustomer && selectedCustomer.id === updatedCustomer.id) {
        setSelectedCustomer(updatedCustomer);
      }
      
      console.log(`Successfully updated customer ${updatedCustomer.name}, totalPlayTime: ${updatedCustomer.totalPlayTime}`);
      
      toast({
        title: 'Success',
        description: 'Customer updated successfully',
      });
      
      return updatedCustomer;
    } catch (error) {
      console.error('Error in updateCustomer:', error);
      toast({
        title: 'Error',
        description: 'Failed to update customer',
        variant: 'destructive'
      });
      return null;
    }
  };
  
  const deleteCustomer = async (id: string) => {
    try {
      console.log('Attempting to delete customer with ID:', id);
      
      // First, check if customer has any active sessions
      const { data: activeSessions, error: sessionsError } = await supabase
        .from('sessions')
        .select('id')
        .eq('customer_id', id)
        .is('end_time', null);
        
      if (sessionsError) {
        console.error('Error checking active sessions:', sessionsError);
        // Continue with the operation since we've updated the schema to handle deletion
      } else if (activeSessions && activeSessions.length > 0) {
        toast({
          title: 'Cannot Delete Customer',
          description: 'This customer has active sessions. Please end all sessions before deleting.',
          variant: 'destructive'
        });
        return;
      }

      // We've already updated the database schema to set NULL on delete,
      // so we can now safely delete the customer
      const { error } = await supabase
        .from('customers')
        .delete()
        .eq('id', id);
        
      if (error) {
        console.error('Error deleting customer:', error);
        toast({
          title: 'Error',
          description: 'Failed to delete customer: ' + error.message,
          variant: 'destructive'
        });
        return;
      }
      
      setCustomers(customers.filter(c => c.id !== id));
      
      if (selectedCustomer && selectedCustomer.id === id) {
        setSelectedCustomer(null);
      }
      
      toast({
        title: 'Success',
        description: 'Customer deleted successfully',
      });
    } catch (error) {
      console.error('Error in deleteCustomer:', error);
      toast({
        title: 'Error',
        description: 'Failed to delete customer',
        variant: 'destructive'
      });
    }
  };
  
  const selectCustomer = (id: string | null) => {
    if (!id) {
      setSelectedCustomer(null);
      return;
    }
    
    const customer = customers.find(c => c.id === id);
    
    if (customer) {
      if (customer.isMember && customer.membershipExpiryDate) {
        const expiryDate = new Date(customer.membershipExpiryDate);
        
        if (expiryDate < new Date()) {
          toast({
            title: "Membership Expired",
            description: `${customer.name}'s membership has expired on ${expiryDate.toLocaleDateString()}`,
            variant: "destructive"
          });
          
          const updatedCustomer = {
            ...customer,
            isMember: false
          };
          
          updateCustomer(updatedCustomer);
          setSelectedCustomer(updatedCustomer);
          return;
        }
        
        if (customer.membershipHoursLeft !== undefined && customer.membershipHoursLeft <= 0) {
          toast({
            title: "Membership Hours Depleted",
            description: `${customer.name} has no remaining hours on their membership plan`,
            variant: "destructive"
          });
        }
      }
      
      setSelectedCustomer(customer);
    } else {
      setSelectedCustomer(null);
    }
  };
  
  const checkMembershipValidity = (customerId: string): boolean => {
    const customer = customers.find(c => c.id === customerId);
    
    if (!customer) return false;
    if (!customer.isMember) return false;
    
    if (customer.membershipExpiryDate) {
      const expiryDate = new Date(customer.membershipExpiryDate);
      if (expiryDate < new Date()) {
        toast({
          title: "Membership Expired",
          description: `${customer.name}'s membership has expired on ${expiryDate.toLocaleDateString()}`,
          variant: "destructive"
        });
        
        updateCustomer({
          ...customer,
          isMember: false
        });
        
        return false;
      }
    }
    
    if (customer.membershipHoursLeft !== undefined && customer.membershipHoursLeft <= 0) {
      toast({
        title: "No Hours Remaining",
        description: `${customer.name} has used all allocated hours in their membership plan`,
        variant: "destructive"
      });
      return false;
    }
    
    return true;
  };
  
  const deductMembershipHours = (customerId: string, hours: number): boolean => {
    const customer = customers.find(c => c.id === customerId);
    
    if (!customer || !customer.isMember || customer.membershipHoursLeft === undefined) {
      return false;
    }
    
    if (customer.membershipHoursLeft < hours) {
      toast({
        title: "Insufficient Hours",
        description: `Customer only has ${customer.membershipHoursLeft} hours remaining`,
        variant: "destructive"
      });
      return false;
    }
    
    const updatedCustomer = {
      ...customer,
      membershipHoursLeft: customer.membershipHoursLeft - hours
    };
    
    updateCustomer(updatedCustomer);
    return true;
  };
  
  return {
    customers,
    setCustomers,
    selectedCustomer,
    setSelectedCustomer,
    addCustomer,
    updateCustomer,
    updateCustomerMembership,
    deleteCustomer,
    selectCustomer,
    checkMembershipValidity,
    deductMembershipHours
  };
};
