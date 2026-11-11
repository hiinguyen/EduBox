import type { Metadata } from "next";
import { Inter, Plus_Jakarta_Sans } from "next/font/google";
import localFont from "next/font/local";
import type { ReactNode } from "react";
import "./globals.css";

const inter = Inter({
  subsets: ["latin", "vietnamese"],
  variable: "--font-inter",
  display: "swap",
});

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ["latin", "vietnamese"],
  variable: "--font-plus-jakarta",
  display: "swap",
});

const materialSymbols = localFont({
  src: "./fonts/material-symbols-outlined.woff2",
  variable: "--font-material-symbols",
  display: "block",
  weight: "400",
});

export const metadata: Metadata = {
  title: {
    default: "EduBox - Nền Tảng Học Thông Minh",
    template: "%s - EduBox",
  },
  description: "Học tập cùng trợ lý AI, thi trực tuyến, cổng phụ huynh và không gian giáo viên.",
};

export default function RootLayout({ children }: { readonly children: ReactNode }) {
  return (
    <html
      lang="vi"
      className={`${inter.variable} ${plusJakarta.variable} ${materialSymbols.variable}`}
    >
      <body className="min-h-screen bg-surface font-body-md text-body-md text-on-surface antialiased">
        {children}
      </body>
    </html>
  );
}
