import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "./components/Sidebar";
import { LanguageProvider } from "./context/LanguageContext";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Private Script Hub",
  description: "Self-hosted script repository",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-black text-gray-100 h-screen flex overflow-hidden`}>
        <LanguageProvider>
          <Sidebar />
          <main className="flex-1 overflow-auto bg-gray-950 p-8">
            {children}
          </main>
        </LanguageProvider>
      </body>
    </html>
  );
}
