"use client";

import { RouteError } from "@/components/ui/route-error";

interface ErrorProps {
  readonly reset: () => void;
}

export default function ErrorState({ reset }: ErrorProps) {
  return <RouteError screenTitle="Cổng Phụ huynh" reset={reset} />;
}
