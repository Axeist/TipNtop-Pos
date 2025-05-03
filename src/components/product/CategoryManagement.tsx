
import React, { useState, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { usePOS } from '@/context/POSContext';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Edit2, Trash2, Plus } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { 
  AlertDialog, 
  AlertDialogAction, 
  AlertDialogCancel, 
  AlertDialogContent, 
  AlertDialogDescription, 
  AlertDialogFooter, 
  AlertDialogHeader, 
  AlertDialogTitle 
} from '@/components/ui/alert-dialog';

const CategoryManagement: React.FC = () => {
  const { categories, addCategory, updateCategory, deleteCategory } = usePOS();
  const { toast } = useToast();

  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [newCategory, setNewCategory] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [editedCategory, setEditedCategory] = useState('');

  const handleAddCategory = () => {
    if (!newCategory.trim()) {
      toast({
        title: 'Error',
        description: 'Category name cannot be empty',
        variant: 'destructive',
      });
      return;
    }

    if (categories.includes(newCategory.trim())) {
      toast({
        title: 'Error',
        description: `Category "${newCategory}" already exists`,
        variant: 'destructive',
      });
      return;
    }

    addCategory(newCategory.trim());
    setNewCategory('');
    setIsAddDialogOpen(false);

    toast({
      title: 'Success',
      description: `Category "${newCategory}" has been added`,
    });
  };

  const handleEditCategory = () => {
    if (!editedCategory.trim()) {
      toast({
        title: 'Error',
        description: 'Category name cannot be empty',
        variant: 'destructive',
      });
      return;
    }

    if (categories.includes(editedCategory.trim()) && editedCategory.trim() !== selectedCategory) {
      toast({
        title: 'Error',
        description: `Category "${editedCategory}" already exists`,
        variant: 'destructive',
      });
      return;
    }

    updateCategory(selectedCategory, editedCategory.trim());
    setEditedCategory('');
    setSelectedCategory('');
    setIsEditDialogOpen(false);

    toast({
      title: 'Success',
      description: `Category has been updated to "${editedCategory}"`,
    });
  };

  const handleDeleteCategory = () => {
    deleteCategory(selectedCategory);
    setSelectedCategory('');
    setIsDeleteDialogOpen(false);

    toast({
      title: 'Success',
      description: `Category "${selectedCategory}" has been deleted`,
    });
  };

  const openEditDialog = (category: string) => {
    setSelectedCategory(category);
    setEditedCategory(category);
    setIsEditDialogOpen(true);
  };

  const openDeleteDialog = (category: string) => {
    setSelectedCategory(category);
    setIsDeleteDialogOpen(true);
  };

  const defaultCategories = ['food', 'drinks', 'tobacco', 'challenges', 'membership'];
  const isDefaultCategory = (category: string) => defaultCategories.includes(category);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-xl">Product Categories</CardTitle>
        <Button 
          onClick={() => setIsAddDialogOpen(true)} 
          variant="outline" 
          size="sm" 
          className="h-8"
        >
          <Plus className="h-4 w-4 mr-1" /> Add Category
        </Button>
      </CardHeader>
      <CardContent>
        <div className="flex flex-wrap gap-2">
          {categories.map((category) => (
            <div key={category} className="flex items-center">
              <Badge 
                variant={isDefaultCategory(category) ? "secondary" : "default"}
                className="px-3 py-1 text-sm"
              >
                {category}
              </Badge>
              {!isDefaultCategory(category) && (
                <div className="flex ml-1">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-6 w-6 p-0" 
                    onClick={() => openEditDialog(category)}
                  >
                    <Edit2 className="h-3 w-3" />
                  </Button>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-6 w-6 p-0" 
                    onClick={() => openDeleteDialog(category)}
                  >
                    <Trash2 className="h-3 w-3" />
                  </Button>
                </div>
              )}
            </div>
          ))}
        </div>
      </CardContent>

      {/* Add Category Dialog */}
      <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Add New Category</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <Input
              value={newCategory}
              onChange={(e) => setNewCategory(e.target.value)}
              placeholder="Enter category name"
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleAddCategory}>Add Category</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Category Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Edit Category</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <Input
              value={editedCategory}
              onChange={(e) => setEditedCategory(e.target.value)}
              placeholder="Enter new category name"
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleEditCategory}>Update Category</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Category Confirmation */}
      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirm Deletion</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete the category "{selectedCategory}"? All products in this category will be moved to the "uncategorized" category.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setIsDeleteDialogOpen(false)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDeleteCategory}>Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Card>
  );
};

export default CategoryManagement;
