interface IconProps {
  readonly name: string;
  readonly filled?: boolean;
  readonly className?: string;
}

export function Icon({ name, filled = false, className }: IconProps) {
  return (
    <span
      aria-hidden="true"
      className={className ? `material-symbols-outlined ${className}` : "material-symbols-outlined"}
      style={filled ? { fontVariationSettings: "'FILL' 1" } : undefined}
    >
      {name}
    </span>
  );
}
