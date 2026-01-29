import { NextResponse } from 'next/server';
import { getAllScripts, saveScript } from '@/lib/file-system';
import path from 'path';

export const dynamic = 'force-dynamic';

export async function GET() {
    const categories = getAllScripts();
    return NextResponse.json(categories);
}

export async function POST(request: Request) {
    try {
        const formData = await request.formData();
        const file = formData.get('file') as File;
        const category = formData.get('category') as string;
        const filename = formData.get('filename') as string;
        const contentText = formData.get('content') as string;

        if (!filename) {
            return NextResponse.json({ error: 'Filename required' }, { status: 400 });
        }

        let finalContent = '';
        if (file) {
            finalContent = await file.text();
        } else if (contentText) {
            finalContent = contentText;
        } else {
            return NextResponse.json({ error: 'Content required' }, { status: 400 });
        }

        // Determine path
        let relativePath = filename;
        if (category && category !== 'Uncategorized') {
            relativePath = path.join(category, filename);
        }

        // Save
        const success = saveScript(relativePath, finalContent);

        if (success) {
            return NextResponse.json({ success: true });
        } else {
            return NextResponse.json({ error: 'Failed to save' }, { status: 500 });
        }

    } catch (e) {
        console.error(e);
        return NextResponse.json({ error: 'Error processing request' }, { status: 500 });
    }
}

export async function DELETE(request: Request) {
    try {
        const { searchParams } = new URL(request.url);
        const scriptPath = searchParams.get('path');

        if (!scriptPath) {
            return NextResponse.json({ error: 'Path required' }, { status: 400 });
        }

        // Import dynamically to avoid build time issues if any? Should be fine.
        // But we need to export deleteScript from file-system first.
        const { deleteScript } = await import('@/lib/file-system');

        if (deleteScript(scriptPath)) {
            return NextResponse.json({ success: true });
        } else {
            return NextResponse.json({ error: 'Failed to delete' }, { status: 500 });
        }
    } catch (e) {
        return NextResponse.json({ error: 'Error deleting script' }, { status: 500 });
    }
}
