
import { Customer } from '@/types/pos.types';

/**
 * Determines if a customer's membership is currently active
 */
export const isMembershipActive = (customer: Customer): boolean => {
  if (!customer.isMember || !customer.membershipExpiryDate) return false;
  
  // Check both expiry date and hours left
  const expiryDate = new Date(customer.membershipExpiryDate);
  const hasValidHours = customer.membershipHoursLeft === undefined || customer.membershipHoursLeft > 0;
  
  return expiryDate > new Date() && hasValidHours;
};

/**
 * Generates the text to display on a membership badge
 */
export const getMembershipBadgeText = (customer: Customer): string => {
  if (!customer.isMember) return 'Non-Member';
  
  const duration = customer.membershipDuration || 
                   (customer.membershipPlan?.toLowerCase().includes('weekly') ? 'Weekly' : 
                    customer.membershipPlan?.toLowerCase().includes('monthly') ? 'Monthly' : '');
  
  let tier = '';
  if (customer.membershipPlan) {
    if (customer.membershipPlan.includes('Silver')) {
      tier = 'Silver';
    } else if (customer.membershipPlan.includes('Gold')) {
      tier = 'Gold';
    } else if (customer.membershipPlan.includes('Platinum')) {
      tier = 'Platinum';
    }
  }
  
  let type = '';
  if (customer.membershipPlan) {
    if (customer.membershipPlan.includes('PS5')) {
      type = 'PS5';
    } else if (customer.membershipPlan.includes('8-Ball')) {
      type = '8-Ball';
    } else if (customer.membershipPlan.includes('Combo')) {
      type = 'Combo';
    } else if (customer.membershipPlan.includes('Ultimate')) {
      type = 'Ultimate';
    }
  }
  
  return `${tier} ${type} ${duration}`;
};

/**
 * Gets the appropriate color class for hours left indicator
 */
export const getHoursLeftColor = (hoursLeft: number | undefined): string => {
  if (hoursLeft === undefined) return '';
  
  if (hoursLeft <= 0) return 'text-red-600';
  if (hoursLeft < 2) return 'text-orange-500';
  return 'text-green-600';
};

/**
 * Calculate membership status and determine if play time should be deducted from membership hours
 */
export const shouldDeductFromMembership = (customer: Customer): boolean => {
  return isMembershipActive(customer) && 
         customer.membershipHoursLeft !== undefined && 
         customer.membershipHoursLeft > 0;
};

/**
 * Convert play time minutes to hours for membership deduction
 */
export const convertMinutesToMembershipHours = (minutes: number): number => {
  return parseFloat((minutes / 60).toFixed(2));
};
