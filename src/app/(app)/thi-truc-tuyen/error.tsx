"use client";

import { RouteError } from "@/components/ui/route-error";

interface ErrorProps {
  readonly reset: () => void;
}

export default function Error({ reset }: ErrorProps) {
  return <RouteError screenTitle="bài thi" reset={reset} />;
}
