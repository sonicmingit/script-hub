import { NextResponse } from 'next/server';
import { getAllScripts } from '@/lib/file-system';

/**
 * CLI 脚本列表 API
 * 返回所有脚本的 JSON 列表，供命令行工具使用
 */
export async function GET() {
    try {
        const categoriesData = await getAllScripts();

        // 格式化输出数据
        const formattedData: Record<string, any[]> = {};

        categoriesData.forEach(cat => {
            formattedData[cat.name] = cat.scripts.map(script => ({
                name: script.name,
                path: script.path,
                extension: script.extension,
                description: script.description || ''
            }));
        });

        const totalScripts = categoriesData.reduce((acc, cat) => acc + cat.scripts.length, 0);

        return NextResponse.json({
            success: true,
            total: totalScripts,
            categories: categoriesData.length,
            data: formattedData
        });
    } catch (error) {
        return NextResponse.json(
            { success: false, error: '获取脚本列表失败' },
            { status: 500 }
        );
    }
}
