import { useState, useEffect, useCallback } from "react";
import { supabase } from "@/integrations/supabase/client";

export interface CouponConfigRow {
  code: string;
  enabled: boolean;
  show_popup: boolean;
}

export function useCouponConfig() {
  const [configs, setConfigs] = useState<CouponConfigRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchConfigs = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error: e } = await supabase
      .from("coupon_config")
      .select("code, enabled, show_popup")
      .order("code");
    if (e) {
      setError(e.message);
      setConfigs([]);
    } else {
      setConfigs(data ?? []);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchConfigs();
  }, [fetchConfigs]);

  const updateEnabled = useCallback(
    async (code: string, enabled: boolean) => {
      const { error: e } = await supabase
        .from("coupon_config")
        .update({ enabled })
        .eq("code", code);
      if (e) throw e;
      setConfigs((prev) =>
        prev.map((c) => (c.code === code ? { ...c, enabled } : c))
      );
    },
    []
  );

  const updateAllEnabled = useCallback(async (enabled: boolean) => {
    const { error: e } = await supabase
      .from("coupon_config")
      .update({ enabled });
    if (e) throw e;
    setConfigs((prev) => prev.map((c) => ({ ...c, enabled })));
  }, []);

  const enabledCodes = configs.filter((c) => c.enabled).map((c) => c.code);
  const popupCouponCodes = configs.filter((c) => c.enabled && c.show_popup).map((c) => c.code);
  const configByCode = Object.fromEntries(configs.map((c) => [c.code, c]));

  return {
    configs,
    configByCode,
    enabledCodes,
    popupCouponCodes,
    loading,
    error,
    refetch: fetchConfigs,
    updateEnabled,
    updateAllEnabled,
  };
}
