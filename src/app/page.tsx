import Link from "next/link";
import { SCREENS } from "@/lib/screens";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-3xl p-8">
      <h1 className="text-3xl font-bold">EduBox</h1>
      <p className="mt-2 text-slate-600">Nền Tảng Học Thông Minh</p>
      <ul className="mt-8 grid gap-4 sm:grid-cols-2">
        {SCREENS.map((s) => (
          <li key={s.href}>
            <Link
              href={s.href}
              className="block rounded-xl border border-slate-200 bg-white p-4 hover:border-indigo-500"
            >
              <h2 className="font-semibold">{s.title}</h2>
              <p className="mt-1 text-sm text-slate-600">{s.description}</p>
            </Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
