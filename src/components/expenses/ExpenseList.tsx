
import React from 'react';
import { useExpenses } from '@/context/ExpenseContext';
import { format } from 'date-fns';
import { Expense } from '@/types/expense.types';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { CurrencyDisplay } from '@/components/ui/currency';
import ExpenseDialog from './ExpenseDialog';
import { PlusCircle, Pencil, Trash2 } from 'lucide-react';
import { 
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface ExpenseListProps {
  selectedMonth?: string;
}

const getCategoryColor = (category: string) => {
  switch (category) {
    case 'rent':
      return 'bg-blue-500';
    case 'utilities':
      return 'bg-green-500';
    case 'salary':
      return 'bg-purple-500';
    case 'restock':
      return 'bg-orange-500';
    default:
      return 'bg-gray-500';
  }
};

const ExpenseList: React.FC<ExpenseListProps> = ({ selectedMonth }) => {
  const { expenses, deleteExpense } = useExpenses();
  
  // Filter expenses based on the selected month
  const filteredExpenses = expenses.filter(expense => {
    if (!selectedMonth || selectedMonth === 'all') return true;
    
    const expenseDate = new Date(expense.date);
    const currentYear = new Date().getFullYear();
    const monthIndex = parseInt(selectedMonth);
    
    return expenseDate.getMonth() === monthIndex && expenseDate.getFullYear() === currentYear;
  });
  
  const formatErrorMessage = (error: unknown): string => {
    if (error && typeof error === 'object' && 'message' in error) {
      return error.message as string;
    }
    return 'An unknown error occurred';
  };
  
  const handleDeleteExpense = async (id: string) => {
    try {
      await deleteExpense(id);
    } catch (error) {
      console.error('Error deleting expense:', formatErrorMessage(error));
    }
  };
  
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>
          {selectedMonth && selectedMonth !== 'all' 
            ? `Expenses for ${new Date(new Date().getFullYear(), parseInt(selectedMonth)).toLocaleString('default', { month: 'long' })}`
            : 'Recent Expenses'
          }
        </CardTitle>
        <ExpenseDialog>
          <Button variant="default" className="flex items-center gap-2">
            <PlusCircle className="h-4 w-4" />
            Add Expense
          </Button>
        </ExpenseDialog>
      </CardHeader>
      <CardContent>
        {filteredExpenses.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No expenses found. Add your first expense by clicking the button above.
          </div>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Recurring</TableHead>
                  <TableHead className="w-[100px] text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredExpenses.map((expense) => (
                  <TableRow key={expense.id}>
                    <TableCell>{expense.name}</TableCell>
                    <TableCell>
                      <Badge className={`${getCategoryColor(expense.category)}`}>
                        {expense.category.charAt(0).toUpperCase() + expense.category.slice(1)}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <CurrencyDisplay amount={expense.amount} />
                    </TableCell>
                    <TableCell>
                      {format(new Date(expense.date), 'MMM dd, yyyy')}
                    </TableCell>
                    <TableCell>
                      {expense.isRecurring ? (
                        <Badge variant="outline" className="bg-blue-100 text-blue-800 border-blue-200">
                          {expense.frequency}
                        </Badge>
                      ) : (
                        <Badge variant="outline" className="bg-gray-100 text-gray-800 border-gray-200">
                          one-time
                        </Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <ExpenseDialog expense={expense}>
                          <Button variant="ghost" size="icon" className="h-8 w-8">
                            <Pencil className="h-4 w-4" />
                          </Button>
                        </ExpenseDialog>
                        
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-red-500 hover:text-red-600 hover:bg-red-50">
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Delete Expense</AlertDialogTitle>
                              <AlertDialogDescription>
                                Are you sure you want to delete this expense? This action cannot be undone.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction 
                                onClick={() => handleDeleteExpense(expense.id)}
                                className="bg-red-500 hover:bg-red-600"
                              >
                                Delete
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default ExpenseList;
