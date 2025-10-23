// src/pages/StaffManagement.tsx
import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Users, UserPlus, Calendar, FileText, DollarSign, Activity } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import StaffOverview from '@/components/staff/StaffOverview';
import StaffDirectory from '@/components/staff/StaffDirectory';
import AttendanceManagement from '@/components/staff/AttendanceManagement';
import LeaveManagement from '@/components/staff/LeaveManagement';
import PayrollManagement from '@/components/staff/PayrollManagement';
import CreateStaffDialog from '@/components/staff/CreateStaffDialog';

const StaffManagement = () => {
  const { toast } = useToast();
  const [staffProfiles, setStaffProfiles] = useState<any[]>([]);
  const [activeShifts, setActiveShifts] = useState<any[]>([]);
  const [pendingLeaves, setPendingLeaves] = useState<any[]>([]);
  const [monthlyPayroll, setMonthlyPayroll] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);

  useEffect(() => {
    fetchStaffData();
  }, []);

  const fetchStaffData = async () => {
    setIsLoading(true);
    try {
      // Fetch staff profiles
      const { data: profiles, error: profilesError } = await supabase
        .from('staff_profiles')
        .select('*')
        .order('created_at', { ascending: false });

      if (profilesError) throw profilesError;
      setStaffProfiles(profiles || []);

      // Fetch active shifts
      const { data: shifts, error: shiftsError } = await supabase
        .from('today_active_shifts')
        .select('*');

      if (shiftsError) throw shiftsError;
      setActiveShifts(shifts || []);

      // Fetch pending leaves
      const { data: leaves, error: leavesError } = await supabase
        .from('pending_leaves_view')
        .select('*');

      if (leavesError) throw leavesError;
      setPendingLeaves(leaves || []);

      // Calculate monthly payroll
      const currentMonth = new Date().getMonth() + 1;
      const currentYear = new Date().getFullYear();
      
      const { data: payroll, error: payrollError } = await supabase
        .from('staff_payslip_view')
        .select('net_salary')
        .eq('month', currentMonth)
        .eq('year', currentYear);

      if (payrollError) throw payrollError;
      
      const total = (payroll || []).reduce((sum, p) => sum + (p.net_salary || 0), 0);
      setMonthlyPayroll(total);

    } catch (error: any) {
      console.error('Error fetching staff data:', error);
      toast({
        title: 'Error',
        description: 'Failed to load staff data',
        variant: 'destructive'
      });
    } finally {
      setIsLoading(false);
    }
  };

  const stats = {
    totalStaff: staffProfiles.length,
    activeStaff: staffProfiles.filter(s => s.is_active).length,
    inactiveStaff: staffProfiles.filter(s => !s.is_active).length,
    activeNow: activeShifts.length,
    pendingLeaves: pendingLeaves.length,
    monthlyPayroll: monthlyPayroll
  };

  return (
    <div className="flex-1 space-y-6 p-6 text-white">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight gradient-text font-heading">
            Staff Management
          </h2>
          <p className="text-muted-foreground mt-1">
            Manage your team, track attendance, and process payroll
          </p>
        </div>
        <Button
          onClick={() => setShowCreateDialog(true)}
          className="bg-cuephoria-purple hover:bg-cuephoria-lightpurple"
        >
          <UserPlus className="mr-2 h-4 w-4" />
          Add Staff Member
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card className="bg-cuephoria-dark border-cuephoria-purple/20">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white">Total Staff</CardTitle>
            <Users className="h-4 w-4 text-cuephoria-lightpurple" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{stats.totalStaff}</div>
            <p className="text-xs text-muted-foreground">
              {stats.inactiveStaff} inactive
            </p>
          </CardContent>
        </Card>

        <Card className="bg-cuephoria-dark border-cuephoria-purple/20">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white">Active Now</CardTitle>
            <Activity className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{stats.activeNow}</div>
            <p className="text-xs text-muted-foreground">
              Currently clocked in
            </p>
          </CardContent>
        </Card>

        <Card className="bg-cuephoria-dark border-cuephoria-purple/20">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white">Pending Leaves</CardTitle>
            <Calendar className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">{stats.pendingLeaves}</div>
            <p className="text-xs text-muted-foreground">
              Awaiting approval
            </p>
          </CardContent>
        </Card>

        <Card className="bg-cuephoria-dark border-cuephoria-purple/20">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-white">Monthly Payroll</CardTitle>
            <DollarSign className="h-4 w-4 text-cuephoria-blue" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">
              ₹{stats.monthlyPayroll.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              Total monthly cost
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-5 bg-cuephoria-dark border border-cuephoria-purple/20">
          <TabsTrigger value="overview">
            <Users className="h-4 w-4 mr-2" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="directory">
            <Users className="h-4 w-4 mr-2" />
            Directory
          </TabsTrigger>
          <TabsTrigger value="attendance">
            <Activity className="h-4 w-4 mr-2" />
            Attendance
          </TabsTrigger>
          <TabsTrigger value="leaves">
            <Calendar className="h-4 w-4 mr-2" />
            Leaves
          </TabsTrigger>
          <TabsTrigger value="payroll">
            <DollarSign className="h-4 w-4 mr-2" />
            Payroll
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4 mt-6">
          <StaffOverview
            staffProfiles={staffProfiles}
            activeShifts={activeShifts}
            isLoading={isLoading}
            onRefresh={fetchStaffData}
          />
        </TabsContent>

        <TabsContent value="directory" className="space-y-4 mt-6">
          <StaffDirectory
            staffProfiles={staffProfiles}
            isLoading={isLoading}
            onRefresh={fetchStaffData}
          />
        </TabsContent>

        <TabsContent value="attendance" className="space-y-4 mt-6">
          <AttendanceManagement
            staffProfiles={staffProfiles}
            activeShifts={activeShifts}
            isLoading={isLoading}
            onRefresh={fetchStaffData}
          />
        </TabsContent>

        <TabsContent value="leaves" className="space-y-4 mt-6">
          <LeaveManagement
            pendingLeaves={pendingLeaves}
            isLoading={isLoading}
            onRefresh={fetchStaffData}
          />
        </TabsContent>

        <TabsContent value="payroll" className="space-y-4 mt-6">
          <PayrollManagement
            staffProfiles={staffProfiles}
            isLoading={isLoading}
            onRefresh={fetchStaffData}
          />
        </TabsContent>
      </Tabs>

      {/* Create Staff Dialog */}
      <CreateStaffDialog
        open={showCreateDialog}
        onOpenChange={setShowCreateDialog}
        onSuccess={fetchStaffData}
      />
    </div>
  );
};

export default StaffManagement;
