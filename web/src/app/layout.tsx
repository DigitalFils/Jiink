import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { Providers } from "./providers";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const APP_NAME = "S8LL"
const APP_DESCRIPTION =
  "S8LL Marketplace — the ultimate blend of Avito, Dewu, PDD and Xiaohongshu. Live shopping, AR try-on, AI assistant, group buys and authenticated drops."

export const metadata: Metadata = {
  metadataBase: new URL("https://s8ll.app"),
  title: {
    default: "S8LL — Ultimate Marketplace",
    template: "%s · S8LL",
  },
  description: APP_DESCRIPTION,
  applicationName: APP_NAME,
  keywords: [
    "S8LL",
    "marketplace",
    "sneakers",
    "live shopping",
    "AR try-on",
    "group buy",
    "authenticated sneakers",
    "PDD",
    "Dewu",
  ],
  manifest: "/manifest.webmanifest",
  icons: {
    icon: [
      { url: "/favicon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/icon-192.png", sizes: "192x192", type: "image/png" },
    ],
    apple: [{ url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
  openGraph: {
    type: "website",
    siteName: "S8LL Marketplace",
    title: "S8LL — Ultimate Marketplace",
    description: APP_DESCRIPTION,
    url: "/",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "S8LL — live shopping, AR try-on, group buys, AI assistant",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "S8LL — Ultimate Marketplace",
    description: APP_DESCRIPTION,
    images: ["/og-image.png"],
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: APP_NAME,
  },
  formatDetection: { telephone: false },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, "max-image-preview": "large" },
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#0A0A0A" },
    { media: "(prefers-color-scheme: light)", color: "#F5F5F7" },
  ],
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.variable} font-sans antialiased bg-background text-foreground`}>
        <Providers>
          {children}
          <Toaster />
        </Providers>
      </body>
    </html>
  );
}
