"use client";

import { RouteError } from "@/components/ui/route-error";

interface ErrorProps {
  readonly reset: () => void;
}

export default function Error({ reset }: ErrorProps) {
  return <RouteError screenTitle="trang học tập" reset={reset} />;
}
