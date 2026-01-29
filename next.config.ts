import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  async rewrites() {
    return [
      {
        source: '/script',
        destination: '/api/cli/script',
      },
      {
        source: '/raw/:path*',
        destination: '/api/raw/:path*',
      },
    ];
  },
};

export default nextConfig;
