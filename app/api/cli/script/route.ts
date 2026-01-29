import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';

/**
 * CLI 脚本下载端点
 * 返回一个可执行的 bash 脚本，动态替换服务器地址
 * 使用方法: curl -sL http://server:7524/api/cli/script | bash
 */
export async function GET(request: NextRequest) {
    try {
        // 获取请求的 host
        const host = request.headers.get('host') || 'localhost:7524';
        const protocol = request.headers.get('x-forwarded-proto') || 'http';
        const serverUrl = `${protocol}://${host}`;

        // 读取模板文件
        const templatePath = path.join(process.cwd(), 'public', 'cli-template.sh');
        let script = await fs.readFile(templatePath, 'utf-8');

        // 替换服务器地址
        script = script.replace(/__SERVER_URL__/g, serverUrl);

        // 返回脚本
        return new NextResponse(script, {
            headers: {
                'Content-Type': 'text/plain; charset=utf-8',
                'Content-Disposition': 'inline; filename="cli.sh"',
            },
        });
    } catch (error) {
        console.error('CLI script generation error:', error);
        return new NextResponse(
            '#!/bin/bash\necho "Error: 无法生成 CLI 脚本"\nexit 1',
            {
                status: 500,
                headers: { 'Content-Type': 'text/plain' },
            }
        );
    }
}
