import { Icon } from "@/components/ui/icon";
import { signOutAction } from "@/lib/auth/actions";

interface SignOutButtonProps {
  readonly className?: string;
}

/** Server-action form button used by the account menu and the mobile menu. */
export function SignOutButton({ className }: SignOutButtonProps) {
  return (
    <form action={signOutAction}>
      <button type="submit" className={className}>
        <Icon name="logout" className="text-[20px]" />
        Đăng xuất
      </button>
    </form>
  );
}
