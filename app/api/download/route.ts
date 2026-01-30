import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';
import archiver from 'archiver';
import { Readable } from 'stream';

const DATA_DIR = path.join(process.cwd(), 'data', 'scripts');

export async function GET() {
    try {
        // 检查目录是否存在
        if (!fs.existsSync(DATA_DIR)) {
            return NextResponse.json({ error: 'Scripts directory not found' }, { status: 404 });
        }

        // 创建 zip 压缩流
        const archive = archiver('zip', { zlib: { level: 9 } });

        // 收集所有数据到 buffer
        const chunks: Buffer[] = [];

        archive.on('data', (chunk: Buffer) => {
            chunks.push(chunk);
        });

        // 添加整个 scripts 目录
        archive.directory(DATA_DIR, 'scripts');

        // 完成压缩
        await archive.finalize();

        // 等待所有数据收集完毕
        await new Promise<void>((resolve, reject) => {
            archive.on('end', resolve);
            archive.on('error', reject);
        });

        const buffer = Buffer.concat(chunks);

        return new NextResponse(buffer, {
            status: 200,
            headers: {
                'Content-Type': 'application/zip',
                'Content-Disposition': 'attachment; filename="scripts.zip"',
                'Content-Length': buffer.length.toString(),
            },
        });
    } catch (error) {
        console.error('Download error:', error);
        return NextResponse.json({ error: 'Failed to create archive' }, { status: 500 });
    }
}
