
import React from 'react';
import { Button } from '@/components/ui/button';
import { LucideIcon } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useIsMobile } from '@/hooks/use-mobile';
import { useAuth } from '@/context/AuthContext';
import { toast } from 'sonner';

interface ActionButtonProps {
  icon: LucideIcon;
  label: string;
  path: string;
  iconColor: string;
  description?: string;
  requiresAdmin?: boolean;
}

const ActionButton: React.FC<ActionButtonProps> = ({
  icon: Icon,
  label,
  path,
  iconColor,
  requiresAdmin = false
}) => {
  const navigate = useNavigate();
  const isMobile = useIsMobile();
  const { user } = useAuth();
  
  const handleClick = () => {
    if (requiresAdmin && !user?.isAdmin) {
      toast.error("You don't have permission to access this feature", {
        description: "Please contact an administrator for access"
      });
      return;
    }
    navigate(path);
  };
  
  return (
    <Button 
      onClick={handleClick}
      variant="outline" 
      className="h-16 sm:h-20 w-full bg-[#1A1F2C] border-gray-700 hover:bg-[#2A2F3C] hover:border-purple-500 
      flex items-center justify-center text-center gap-2 p-2 sm:p-4 transition-all duration-300
      overflow-hidden hover:shadow-[0_0_15px_rgba(155,135,245,0.5)] hover:scale-[1.02]
      group relative"
    >
      <Icon className={`h-6 w-6 ${iconColor} shrink-0 group-hover:scale-110 transition-transform`} />
      <span className="text-sm sm:text-base font-medium truncate w-full group-hover:text-white">{label}</span>
    </Button>
  );
};

export default ActionButton;
