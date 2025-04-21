import React, { useState, useEffect } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { ShoppingCart, X, User, Plus, Search, ArrowRight, Trash2, ReceiptIcon, Download, Check, Award } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { usePOS, Customer, Product, Bill } from '@/context/POSContext';
import { CurrencyDisplay, formatCurrency } from '@/components/ui/currency';
import CustomerCard from '@/components/CustomerCard';
import ProductCard from '@/components/ProductCard';
import Receipt from '@/components/Receipt';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Checkbox } from '@/components/ui/checkbox';

const POS = () => {
  const {
    products,
    customers,
    stations,
    cart,
    selectedCustomer,
    discount,
    discountType,
    loyaltyPointsUsed,
    addToCart,
    removeFromCart,
    updateCartItem,
    clearCart,
    selectCustomer,
    setDiscount,
    setLoyaltyPointsUsed,
    calculateTotal,
    completeSale,
  } = usePOS();
  const { toast } = useToast();

  const [activeTab, setActiveTab] = useState('all');
  const [customerSearchQuery, setCustomerSearchQuery] = useState('');
  const [productSearchQuery, setProductSearchQuery] = useState('');
  const [isCustomerDialogOpen, setIsCustomerDialogOpen] = useState(false);
  const [isCheckoutDialogOpen, setIsCheckoutDialogOpen] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'upi'>('cash');
  const [customDiscountAmount, setCustomDiscountAmount] = useState(discount.toString());
  const [customDiscountType, setCustomDiscountType] = useState<'percentage' | 'fixed'>(discountType);
  const [customLoyaltyPoints, setCustomLoyaltyPoints] = useState(loyaltyPointsUsed.toString());
  const [lastCompletedBill, setLastCompletedBill] = useState<Bill | null>(null);
  const [showReceipt, setShowReceipt] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);

  const categoryCounts = products.reduce((acc, product) => {
    const category = product.category;
    acc[category] = (acc[category] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);
  
  categoryCounts.all = products.length;

  useEffect(() => {
    setCustomDiscountAmount(discount.toString());
    setCustomDiscountType(discountType);
    setCustomLoyaltyPoints(loyaltyPointsUsed.toString());
  }, [discount, discountType, loyaltyPointsUsed]);

  useEffect(() => {
    if (isCheckoutDialogOpen) {
      handleApplyDiscount();
      handleApplyLoyaltyPoints();
    }
  }, [isCheckoutDialogOpen]);

  useEffect(() => {
    if (selectedCustomer) {
      console.log("Selected customer changed:", selectedCustomer.name);
      
      const activeStations = stations.filter(
        station => station.isOccupied && 
        station.currentSession && 
        station.currentSession.customerId === selectedCustomer.id
      );
      
      console.log("Active stations for customer:", activeStations.length);
      
      if (activeStations.length > 0) {
        toast({
          title: 'Gaming Sessions Added',
          description: `${activeStations.length} active gaming sessions have been added to the cart.`,
        });
      }
    }
  }, [selectedCustomer]);

  const filteredProducts = activeTab === 'all'
    ? products
    : products.filter(product => product.category === activeTab);

  const searchedProducts = productSearchQuery.trim() === ''
    ? filteredProducts
    : filteredProducts.filter(product =>
        product.name.toLowerCase().includes(productSearchQuery.toLowerCase())
      );

  const filteredCustomers = customerSearchQuery.trim() === ''
    ? customers
    : customers.filter(customer =>
        customer.name.toLowerCase().includes(customerSearchQuery.toLowerCase()) ||
        customer.phone.includes(customerSearchQuery)
      );

  const handleUpdateQuantity = (id: string, newQuantity: number) => {
    if (newQuantity < 1) return;
    updateCartItem(id, newQuantity);
  };

  const handleRemoveItem = (id: string) => {
    removeFromCart(id);
  };

  const handleSelectCustomer = (customer: Customer) => {
    selectCustomer(customer.id);
    setIsCustomerDialogOpen(false);
    toast({
      title: 'Customer Selected',
      description: `${customer.name} has been selected for this transaction.`,
      className: 'bg-cuephoria-purple/90',
    });
  };

  const handleApplyDiscount = () => {
    const amount = Number(customDiscountAmount);
    if (isNaN(amount) || amount < 0) {
      toast({
        title: 'Invalid Discount',
        description: 'Please enter a valid discount amount',
        variant: 'destructive',
      });
      return;
    }
    setDiscount(amount, customDiscountType);
  };

  const handleApplyLoyaltyPoints = () => {
    const points = Number(customLoyaltyPoints);
    if (isNaN(points) || points < 0) {
      toast({
        title: 'Invalid Points',
        description: 'Please enter a valid number of loyalty points',
        variant: 'destructive',
      });
      return;
    }
    
    if (selectedCustomer && points > selectedCustomer.loyaltyPoints) {
      toast({
        title: 'Too Many Points',
        description: `Customer only has ${selectedCustomer.loyaltyPoints} points available`,
        variant: 'destructive',
      });
      return;
    }
    
    setLoyaltyPointsUsed(points);
  };

  const handleCompleteSale = () => {
    if (!selectedCustomer) {
      toast({
        title: 'No Customer Selected',
        description: 'Please select a customer before completing the sale',
        variant: 'destructive',
      });
      return;
    }
    
    if (cart.length === 0) {
      toast({
        title: 'Empty Cart',
        description: 'Please add items to the cart before completing the sale',
        variant: 'destructive',
      });
      return;
    }
    
    try {
      const bill = completeSale(paymentMethod);
      if (bill) {
        setIsCheckoutDialogOpen(false);
        setLastCompletedBill(bill);
        
        setShowSuccess(true);
        
        toast({
          title: 'Sale Completed',
          description: `Total: ${formatCurrency(bill.total)}`,
          className: 'bg-green-600',
        });
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'An error occurred',
        variant: 'destructive',
      });
    }
  };

  const subtotal = cart.reduce((sum, item) => sum + item.total, 0);
  let discountValue = 0;
  if (discountType === 'percentage') {
    discountValue = subtotal * (discount / 100);
  } else {
    discountValue = discount;
  }
  const total = calculateTotal();

  return (
    <div className="flex-1 p-8 pt-6">
      <div className="flex items-center justify-between mb-6 animate-slide-down">
        <h2 className="text-3xl font-bold tracking-tight gradient-text font-heading">Point of Sale</h2>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-1 h-[calc(100vh-12rem)] flex flex-col animate-slide-up">
          <CardHeader className="pb-3 bg-gradient-to-r from-cuephoria-purple/20 to-transparent">
            <div className="flex justify-between items-center">
              <CardTitle className="text-xl font-heading">
                <ShoppingCart className="h-5 w-5 inline-block mr-2 text-cuephoria-lightpurple" />
                Cart
              </CardTitle>
              <Button 
                variant="ghost" 
                size="sm" 
                onClick={clearCart}
                className="hover:text-red-500 transition-colors"
              >
                Clear
              </Button>
            </div>
            <CardDescription>
              {cart.length} {cart.length === 1 ? 'item' : 'items'} in cart
            </CardDescription>
          </CardHeader>
          <CardContent className="flex-grow overflow-auto px-6">
            {cart.length > 0 ? (
              <div className="space-y-4">
                {cart.map((item, index) => (
                  <div 
                    key={item.id} 
                    className={`flex items-center justify-between border-b pb-3 animate-fade-in grid grid-cols-[2fr_1fr_1fr] gap-2`} 
                    style={{animationDelay: `${index * 50}ms`}}
                  >
                    <div className="flex flex-col justify-center">
                      <p className="font-medium font-quicksand truncate">{item.name}</p>
                      <p className="text-xs text-muted-foreground indian-rupee">
                        {item.price.toLocaleString('en-IN')} each
                      </p>
                    </div>
                    <div className="flex items-center justify-center space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-7 w-7 p-0"
                        onClick={() => handleUpdateQuantity(item.id, item.quantity - 1)}
                      >
                        -
                      </Button>
                      <span className="w-8 text-center">{item.quantity}</span>
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-7 w-7 p-0"
                        onClick={() => handleUpdateQuantity(item.id, item.quantity + 1)}
                      >
                        +
                      </Button>
                    </div>
                    <div className="flex flex-col items-end">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-7 w-7 p-0 text-destructive hover:bg-red-500/10 self-end"
                        onClick={() => handleRemoveItem(item.id)}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                      <div className="indian-rupee font-mono text-right">
                        {item.total.toLocaleString('en-IN')}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center h-full animate-fade-in">
                <ShoppingCart className="h-12 w-12 text-muted-foreground mb-4 animate-pulse-soft" />
                <h3 className="text-xl font-medium font-heading">Cart Empty</h3>
                <p className="text-muted-foreground mt-2 text-center">
                  Add products to the cart to begin
                </p>
              </div>
            )}
          </CardContent>
          <CardFooter className="border-t pt-4 flex flex-col bg-gradient-to-r from-transparent to-cuephoria-purple/10">
            <div className="w-full">
              <div className="flex justify-between py-1">
                <span>Subtotal</span>
                <CurrencyDisplay amount={subtotal} />
              </div>
              {discount > 0 && (
                <div className="flex justify-between py-1 text-cuephoria-purple">
                  <span>
                    Discount {discountType === 'percentage' ? `(${discount}%)` : ''}
                  </span>
                  <CurrencyDisplay amount={discountValue} className="text-cuephoria-purple" />
                </div>
              )}
              {loyaltyPointsUsed > 0 && (
                <div className="flex justify-between py-1 text-cuephoria-orange">
                  <span>Loyalty Points Used</span>
                  <CurrencyDisplay amount={loyaltyPointsUsed} className="text-cuephoria-orange" />
                </div>
              )}
              <div className="flex justify-between py-1 text-lg font-bold border-t mt-2 pt-2">
                <span>Total</span>
                <CurrencyDisplay amount={total} className="text-cuephoria-lightpurple" />
              </div>
            </div>
            
            <div className="flex flex-col space-y-3 w-full mt-4">
              <div className="flex space-x-2">
                <Button
                  variant={selectedCustomer ? "outline" : "default"}
                  className={`flex-1 btn-hover-effect ${selectedCustomer ? "" : "bg-gradient-to-r from-cuephoria-purple to-cuephoria-lightpurple"}`}
                  onClick={() => setIsCustomerDialogOpen(true)}
                >
                  {selectedCustomer ? (
                    <div className="flex items-center">
                      <User className="h-4 w-4 mr-2" />
                      {selectedCustomer.name}
                    </div>
                  ) : (
                    <div className="flex items-center">
                      <User className="h-4 w-4 mr-2" />
                      Select Customer
                    </div>
                  )}
                </Button>
              </div>
              <Button 
                variant="default" 
                className="w-full bg-gradient-to-r from-green-500 to-green-600 hover:opacity-90 animate-pulse-soft"
                disabled={cart.length === 0 || !selectedCustomer}
                onClick={() => setIsCheckoutDialogOpen(true)}
              >
                <ReceiptIcon className="mr-2 h-4 w-4" />
                Checkout
              </Button>
            </div>
          </CardFooter>
        </Card>

        <Card
          className="lg:col-span-2 h-full flex flex-col animate-slide-up delay-200 overflow-visible"
          style={{
            minHeight: 0,
          }}
        >
          <CardHeader className="pb-3 bg-gradient-to-r from-transparent to-cuephoria-blue/10">
            <CardTitle className="text-xl font-heading">Products</CardTitle>
            <div className="flex space-x-2">
              <div className="relative flex-1">
                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search products..."
                  className="pl-8 font-quicksand"
                  value={productSearchQuery}
                  onChange={(e) => setProductSearchQuery(e.target.value)}
                />
              </div>
            </div>
          </CardHeader>

          <div
            className="flex flex-col flex-grow px-0"
            style={{
              minHeight: 0,
            }}
          >
            <Tabs
              defaultValue="all"
              value={activeTab}
              onValueChange={setActiveTab}
              className="flex flex-col flex-grow animate-scale-in"
            >
              <div className="px-1 sm:px-6 bg-gradient-to-r from-cuephoria-purple/30 to-cuephoria-blue/20">
                <TabsList
                  className={`
                    flex items-center
                    gap-x-2
                    py-2
                    sm:justify-center
                    justify-start
                    overflow-x-auto
                    scrollbar-thin scrollbar-thumb-cuephoria-lightpurple/30 scrollbar-track-transparent
                    no-scrollbar
                    w-full
                    whitespace-nowrap
                    rounded-xl
                  `}
                  style={{
                    WebkitOverflowScrolling: "touch",
                    paddingBottom: 0,
                  }}
                >
                  <TabsTrigger
                    value="all"
                    className="font-heading whitespace-nowrap transition-all px-5 py-2 rounded-lg text-base font-medium focus:z-10 focus-visible:ring-2 focus-visible:ring-cuephoria-purple/50 data-[state=active]:bg-cuephoria-purple data-[state=active]:text-white data-[state=active]:shadow-md"
                  >
                    All ({categoryCounts.all || 0})
                  </TabsTrigger>
                  <TabsTrigger
                    value="food"
                    className="font-heading whitespace-nowrap transition-all px-5 py-2 rounded-lg text-base font-medium focus:z-10 focus-visible:ring-2 focus-visible:ring-cuephoria-purple/50 data-[state=active]:bg-cuephoria-purple data-[state=active]:text-white data-[state=active]:shadow-md"
                  >
                    Food ({categoryCounts.food || 0})
                  </TabsTrigger>
                  <TabsTrigger
                    value="drinks"
                    className="font-heading whitespace-nowrap transition-all px-5 py-2 rounded-lg text-base font-medium focus:z-10 focus-visible:ring-2 focus-visible:ring-cuephoria-purple/50 data-[state=active]:bg-cuephoria-purple data-[state=active]:text-white data-[state=active]:shadow-md"
                  >
                    Drinks ({categoryCounts.drinks || 0})
                  </TabsTrigger>
                  <TabsTrigger
                    value="tobacco"
                    className="font-heading whitespace-nowrap transition-all px-5 py-2 rounded-lg text-base font-medium focus:z-10 focus-visible:ring-2 focus-visible:ring-cuephoria-purple/50 data-[state=active]:bg-cuephoria-purple data-[state=active]:text-white data-[state=active]:shadow-md"
                  >
                    Tobacco ({categoryCounts.tobacco || 0})
                  </TabsTrigger>
                  <TabsTrigger
                    value="challenges"
                    className="font-heading whitespace-nowrap transition-all px-5 py-2 rounded-lg text-base font-medium focus:z-10 focus-visible:ring-2 focus-visible:ring-cuephoria-purple/50 data-[state=active]:bg-cuephoria-purple data-[state=active]:text-white data-[state=active]:shadow-md"
                  >
                    Challenges ({categoryCounts.challenges || 0})
                  </TabsTrigger>
                  <TabsTrigger
                    value="membership"
                    className="font-heading whitespace-nowrap flex items-center gap-1 transition-all px-5 py-2 rounded-lg text-base font-medium focus:z-10 focus-visible:ring-2 focus-visible:ring-cuephoria-purple/50 data-[state=active]:bg-cuephoria-purple data-[state=active]:text-white data-[state=active]:shadow-md"
                  >
                    <Award className="h-4 w-4" />
                    Membership ({categoryCounts.membership || 0})
                  </TabsTrigger>
                </TabsList>
              </div>

              <TabsContent
                value={activeTab}
                className="flex-grow"
                style={{
                  minHeight: 0,
                  padding: 0,
                  marginTop: 0,
                }}
              >
                <div
                  style={{
                    maxHeight: 'calc(100vh - 14rem)',
                    overflowY: 'auto',
                    padding: '1rem 1.5rem 1.5rem 1.5rem',
                    borderRadius: 'inherit',
                    background: 'inherit',
                    boxShadow: 'inherit',
                    scrollbarGutter: 'stable',
                  }}
                  className="w-full"
                >
                  {searchedProducts.length > 0 ? (
                    <div
                      className="grid gap-3"
                      style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
                      }}
                    >
                      {searchedProducts.map((product, index) => (
                        <div
                          key={product.id}
                          className="animate-scale-in h-full"
                          style={{ animationDelay: `${(index % 5) * 100}ms` }}
                        >
                          <ProductCard product={product} className="h-full" />
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="flex flex-col items-center justify-center h-full animate-fade-in">
                      <h3 className="text-xl font-medium font-heading">No Products Found</h3>
                      <p className="text-muted-foreground mt-2">
                        Try a different search or category
                      </p>
                    </div>
                  )}
                </div>
              </TabsContent>
            </Tabs>
          </div>
        </Card>
      </div>

      <Dialog open={isCustomerDialogOpen} onOpenChange={setIsCustomerDialogOpen}>
        <DialogContent className="max-w-3xl animate-scale-in">
          <DialogHeader>
            <DialogTitle className="font-heading text-xl">Select Customer</DialogTitle>
          </DialogHeader>
          <div className="relative mb-4">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search customers..."
              className="pl-8 font-quicksand"
              value={customerSearchQuery}
              onChange={(e) => setCustomerSearchQuery(e.target.value)}
            />
          </div>
          
          <div className="max-h-[60vh] overflow-auto">
            {filteredCustomers.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {filteredCustomers.map((customer, index) => (
                  <div 
                    key={customer.id} 
                    className={`animate-scale-in delay-${index % 6}`} 
                    style={{animationDelay: `${(index % 6) * 100}ms`}}
                  >
                    <CustomerCard
                      customer={customer}
                      isSelectable={true}
                      onSelect={handleSelectCustomer}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center py-8">
                <User className="h-12 w-12 text-muted-foreground mb-4" />
                <h3 className="text-xl font-medium font-heading">No Customers Found</h3>
                <p className="text-muted-foreground mt-2">
                  Try a different search or add a new customer
                </p>
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={isCheckoutDialogOpen} onOpenChange={setIsCheckoutDialogOpen}>
        <DialogContent className="max-w-md animate-scale-in">
          <DialogHeader>
            <DialogTitle className="font-heading text-xl">Complete Transaction</DialogTitle>
          </DialogHeader>
          
          <div className="space-y-4 py-2">
            {selectedCustomer && (
              <div className="border rounded-md p-3 bg-gradient-to-r from-cuephoria-purple/10 to-transparent animate-fade-in">
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-medium flex items-center">
                      <User className="h-4 w-4 mr-2 text-cuephoria-lightpurple" /> {selectedCustomer.name}
                    </div>
                    <div className="text-sm text-muted-foreground">{selectedCustomer.phone}</div>
                  </div>
                  {selectedCustomer.isMember && (
                    <div className="bg-cuephoria-purple text-white text-xs px-2 py-1 rounded">
                      Member
                    </div>
                  )}
                </div>
                <div className="mt-2 text-sm">
                  Available Points: <span className="font-semibold">{selectedCustomer.loyaltyPoints}</span>
                </div>
              </div>
            )}
            
            <div className="space-y-3 animate-slide-up delay-100">
              <h4 className="font-medium font-heading">Apply Discount</h4>
              <div className="flex space-x-2">
                <div className="flex-1">
                  <Input
                    type="number"
                    value={customDiscountAmount}
                    onChange={(e) => setCustomDiscountAmount(e.target.value)}
                    placeholder="Discount amount"
                    className="font-quicksand"
                  />
                </div>
                <select
                  className="px-3 py-2 rounded-md border border-input bg-background font-quicksand"
                  value={customDiscountType}
                  onChange={(e) => setCustomDiscountType(e.target.value as 'percentage' | 'fixed')}
                >
                  <option value="percentage">%</option>
                  <option value="fixed">₹</option>
                </select>
                <Button 
                  onClick={handleApplyDiscount}
                  className="bg-cuephoria-purple hover:bg-cuephoria-purple/80"
                >
                  Apply
                </Button>
              </div>
            </div>
            
            {selectedCustomer && selectedCustomer.loyaltyPoints > 0 && (
              <div className="space-y-3 animate-slide-up delay-200">
                <h4 className="font-medium font-heading">Use Loyalty Points</h4>
                <div className="flex space-x-2">
                  <Input
                    type="number"
                    value={customLoyaltyPoints}
                    onChange={(e) => setCustomLoyaltyPoints(e.target.value)}
                    placeholder="Points to use"
                    className="font-quicksand"
                  />
                  <Button 
                    onClick={handleApplyLoyaltyPoints}
                    className="bg-cuephoria-orange hover:bg-cuephoria-orange/80"
                  >
                    Apply
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground">
                  Customer has {selectedCustomer.loyaltyPoints} points (₹1 per point)
                </p>
              </div>
            )}
            
            <div className="border-t pt-4 mt-2 animate-slide-up delay-300">
              <div className="flex justify-between py-1">
                <span>Subtotal</span>
                <CurrencyDisplay amount={subtotal} />
              </div>
              {discount > 0 && (
                <div className="flex justify-between py-1 text-cuephoria-purple">
                  <span>
                    Discount {discountType === 'percentage' ? `(${discount}%)` : ''}
                  </span>
                  <CurrencyDisplay amount={discountValue} className="text-cuephoria-purple" />
                </div>
              )}
              {loyaltyPointsUsed > 0 && (
                <div className="flex justify-between py-1 text-cuephoria-orange">
                  <span>Loyalty Points Used</span>
                  <CurrencyDisplay amount={loyaltyPointsUsed} className="text-cuephoria-orange" />
                </div>
              )}
              <div className="flex justify-between py-1 text-lg font-bold border-t mt-2 pt-2">
                <span>Total</span>
                <CurrencyDisplay amount={total} className="text-cuephoria-lightpurple" />
              </div>
            </div>
            
            <div className="space-y-3 animate-slide-up delay-400">
              <h4 className="font-medium font-heading">Payment Method</h4>
              <RadioGroup
                value={paymentMethod}
                onValueChange={(value) => setPaymentMethod(value as 'cash' | 'upi')}
                className="flex space-x-4"
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="cash" id="cash" />
                  <Label htmlFor="cash" className="font-quicksand">Cash</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="upi" id="upi" />
                  <Label htmlFor="upi" className="font-quicksand">UPI</Label>
                </div>
              </RadioGroup>
            </div>
          </div>
          
          <DialogFooter className="animate-slide-up delay-500">
            <Button variant="outline" onClick={() => setIsCheckoutDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleCompleteSale} className="bg-gradient-to-r from-green-500 to-green-600 hover:opacity-90">
              Complete Sale (<CurrencyDisplay amount={total} />)
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={showSuccess} onOpenChange={setShowSuccess}>
        <DialogContent className="max-w-md animate-scale-in text-center">
          <div className="flex flex-col items-center justify-center py-6">
            <div className="rounded-full bg-green-100 p-6 mb-4">
              <Check className="h-12 w-12 text-green-600" />
            </div>
            <DialogTitle className="text-2xl font-heading mb-2">Payment Successful!</DialogTitle>
            <DialogDescription className="text-center mb-6">
              Your transaction has been completed successfully.
            </DialogDescription>
            <p className="font-bold text-xl mb-2">
              <CurrencyDisplay amount={lastCompletedBill?.total || 0} />
            </p>
            <p className="text-sm text-muted-foreground mb-6">
              {lastCompletedBill ? new Date(lastCompletedBill.createdAt).toLocaleString() : ''}
            </p>
            <Button 
              onClick={() => {
                setShowSuccess(false);
                setShowReceipt(true);
              }}
              className="w-full bg-cuephoria-purple hover:bg-cuephoria-purple/90"
            >
              <ReceiptIcon className="mr-2 h-4 w-4" />
              View Receipt
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {showReceipt && lastCompletedBill && selectedCustomer && (
        <Receipt 
          bill={lastCompletedBill} 
          customer={selectedCustomer} 
          onClose={() => setShowReceipt(false)} 
        />
      )}
    </div>
  );
};

export default POS;
