import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';

export async function POST(request: Request) {
    const body = await request.json();
    const { username, password } = body;

    const expectedUser = process.env.ENV_USER || "admin";
    const expectedPass = process.env.ENV_PASSWORD || "123456";

    if (username === expectedUser && password === expectedPass) {
        // Set cookie
        // Note: In Next.js App Router, cookies() is async in some contexts but synchronous in Route Handlers (Wait, in Next 15 it might be async!)
        // Let's check Next 15 breaking changes. cookies() is async in Server Components, but in Route Handlers?
        // "cookies() is now a promise" in Next 15.
        const cookieStore = await cookies();
        cookieStore.set('auth_token', 'logged_in', {
            httpOnly: true,
            path: '/',
            secure: false, // process.env.NODE_ENV === 'production', // Disable secure for HTTP support in self-hosted env
            maxAge: 60 * 60 * 24 * 7, // 1 week
        });

        return NextResponse.json({ success: true });
    }

    return NextResponse.json({ success: false }, { status: 401 });
}
