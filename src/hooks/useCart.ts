import { useState } from 'react';
import { CartItem } from '@/types/pos.types';
import { useToast } from '@/hooks/use-toast';

export const useCart = () => {
  const [cart, setCart] = useState<CartItem[]>([]);
  const [discount, setDiscountAmount] = useState<number>(0);
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed'>('percentage');
  const [loyaltyPointsUsed, setLoyaltyPointsUsedAmount] = useState<number>(0);
  const { toast } = useToast();
  
  const addToCart = (item: Omit<CartItem, 'total'>) => {
    try {
      const processedItem = item.type === 'session' 
        ? { ...item, quantity: 1 } 
        : item;
      
      const existingItem = cart.find(i => 
        i.id === processedItem.id && 
        i.type === processedItem.type
      );
      
      if (existingItem) {
        const updatedCart = cart.map(i => 
          i.id === processedItem.id && i.type === processedItem.type
            ? processedItem.type === 'session'
              ? processedItem  // Replace session item completely
              : { 
                  ...i, 
                  quantity: i.quantity + processedItem.quantity, 
                  total: (i.quantity + processedItem.quantity) * i.price 
                }
            : i
        );
        setCart(updatedCart);
        toast({
          title: "Item Updated",
          description: `Updated ${processedItem.name}`,
        });
      } else {
        const newItem = { 
          ...processedItem, 
          total: processedItem.quantity * processedItem.price 
        };
        setCart([...cart, newItem]);
        toast({
          title: "Item Added",
          description: `Added ${processedItem.name} to cart`,
        });
      }
    } catch (error) {
      console.error("Error adding to cart:", error);
      toast({
        title: "Error",
        description: "Failed to add item to cart",
        variant: "destructive"
      });
    }
  };
  
  const removeFromCart = (id: string) => {
    try {
      const itemToRemove = cart.find(i => i.id === id);
      setCart(cart.filter(i => i.id !== id));
      
      if (itemToRemove) {
        toast({
          title: "Item Removed",
          description: `Removed ${itemToRemove.name} from cart`,
        });
      }
    } catch (error) {
      console.error("Error removing from cart:", error);
      toast({
        title: "Error",
        description: "Failed to remove item",
        variant: "destructive"
      });
    }
  };
  
  const updateCartItem = (id: string, quantity: number) => {
    try {
      const itemToUpdate = cart.find(i => i.id === id);
      if (itemToUpdate?.type === 'session') return;
      
      if (quantity <= 0) {
        removeFromCart(id);
        return;
      }
      
      const updatedCart = cart.map(i => 
        i.id === id
          ? { ...i, quantity, total: quantity * i.price }
          : i
      );
      
      setCart(updatedCart);
      toast({
        title: "Item Updated",
        description: "Updated quantity in cart",
      });
    } catch (error) {
      console.error("Error updating cart item:", error);
      toast({
        title: "Error",
        description: "Failed to update item",
        variant: "destructive"
      });
    }
  };
  
  const clearCart = () => {
    setCart([]);
    setDiscountAmount(0);
    setLoyaltyPointsUsedAmount(0);
    toast({
      title: "Cart Cleared",
      description: "All items removed from cart",
    });
  };
  
  const setDiscount = (amount: number, type: 'percentage' | 'fixed') => {
    setDiscountAmount(amount);
    setDiscountType(type);
    toast({
      title: "Discount Applied",
      description: `${type === 'percentage' ? amount + '%' : '₹' + amount} discount applied`,
    });
  };
  
  const setLoyaltyPointsUsed = (points: number) => {
    setLoyaltyPointsUsedAmount(points);
    if (points > 0) {
      toast({
        title: "Loyalty Points Applied",
        description: `${points} loyalty points used`,
      });
    }
  };
  
  const calculateTotal = () => {
    const subtotal = cart.reduce((sum, item) => sum + item.total, 0);
    
    let discountValue = 0;
    if (discountType === 'percentage') {
      discountValue = subtotal * (discount / 100);
    } else {
      discountValue = discount;
    }
    
    const loyaltyDiscount = loyaltyPointsUsed;
    
    return Math.max(0, subtotal - discountValue - loyaltyDiscount);
  };
  
  return {
    cart,
    setCart,
    discount,
    setDiscountAmount,
    discountType,
    setDiscountType,
    loyaltyPointsUsed,
    setLoyaltyPointsUsedAmount,
    addToCart,
    removeFromCart,
    updateCartItem,
    clearCart,
    setDiscount,
    setLoyaltyPointsUsed,
    calculateTotal
  };
};
