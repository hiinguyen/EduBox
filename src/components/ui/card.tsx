import type { ComponentPropsWithoutRef, ElementType, ReactNode } from "react";

type CardProps<T extends ElementType> = {
  readonly as?: T;
  readonly children: ReactNode;
  readonly className?: string;
} & Omit<ComponentPropsWithoutRef<T>, "as" | "children" | "className">;

const CARD_CLASS = "rounded-xl bg-surface-container-lowest p-space-lg shadow-sm";

export function Card<T extends ElementType = "div">({
  as,
  children,
  className,
  ...rest
}: CardProps<T>) {
  const Component: ElementType = as ?? "div";
  return (
    <Component {...rest} className={className ? `${CARD_CLASS} ${className}` : CARD_CLASS}>
      {children}
    </Component>
  );
}
