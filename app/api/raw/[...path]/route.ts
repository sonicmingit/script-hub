import { NextRequest, NextResponse } from 'next/server';
import { getScriptContent } from '@/lib/file-system';

export async function GET(
    request: NextRequest,
    props: { params: Promise<{ path: string[] }> }
) {
    const params = await props.params;
    const pathArray = params.path;
    const relativePath = pathArray.join('/');

    const content = getScriptContent(relativePath);

    if (content === null) {
        return new NextResponse('File not found', { status: 404 });
    }

    return new NextResponse(content, {
        headers: {
            'Content-Type': 'text/plain; charset=utf-8',
        },
    });
}
