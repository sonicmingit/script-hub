'use client';

import { X, Copy, Check, Download } from "lucide-react";
import { useState, useEffect } from "react";

interface ScriptViewerModalProps {
    isOpen: boolean;
    onClose: () => void;
    scriptPath: string;
    scriptName: string;
}

export function ScriptViewerModal({ isOpen, onClose, scriptPath, scriptName }: ScriptViewerModalProps) {
    const [content, setContent] = useState<string>('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [copied, setCopied] = useState(false);

    useEffect(() => {
        if (isOpen && scriptPath) {
            fetchContent();
        }
    }, [isOpen, scriptPath]);

    const fetchContent = async () => {
        setLoading(true);
        setError('');
        try {
            const res = await fetch(`/api/raw/${scriptPath}`);
            if (!res.ok) throw new Error('Failed to load content');
            const text = await res.text();
            setContent(text);
        } catch (e) {
            setError('无法加载脚本内容');
        } finally {
            setLoading(false);
        }
    };

    const handleCopy = () => {
        // 尝试使用最新的 Clipboard API
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(content)
                .then(() => {
                    setCopied(true);
                    setTimeout(() => setCopied(false), 2000);
                })
                .catch(() => {
                    fallbackCopyTextToClipboard(content);
                });
        } else {
            // 兼容非安全上下文 (HTTP) 或不支持 Clipboard API 的浏览器
            fallbackCopyTextToClipboard(content);
        }
    };

    const fallbackCopyTextToClipboard = (text: string) => {
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.position = "fixed";
        textArea.style.left = "-9999px";
        textArea.style.top = "0";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        try {
            const successful = document.execCommand('copy');
            if (successful) {
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            }
        } catch (err) {
            console.error('Fallback copy failed', err);
        }
        document.body.removeChild(textArea);
    };

    const handleDownload = () => {
        const blob = new Blob([content], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = scriptName;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
            <div className="bg-gray-900 border border-gray-800 rounded-xl w-full max-w-4xl max-h-[85vh] flex flex-col shadow-2xl">
                {/* Header */}
                <div className="flex justify-between items-center p-4 border-b border-gray-800">
                    <h3 className="text-lg font-bold text-white flex gap-2 items-center">
                        <span className="text-blue-400">📄</span>
                        {scriptName}
                    </h3>
                    <div className="flex gap-2">
                        <button onClick={handleCopy} className="p-2 hover:bg-gray-800 rounded text-gray-400 hover:text-white" title="复制内容">
                            {copied ? <Check size={18} className="text-green-500" /> : <Copy size={18} />}
                        </button>
                        <button onClick={handleDownload} className="p-2 hover:bg-gray-800 rounded text-gray-400 hover:text-white" title="下载文件">
                            <Download size={18} />
                        </button>
                        <button onClick={onClose} className="p-2 hover:bg-red-900/30 rounded text-gray-400 hover:text-red-400">
                            <X size={20} />
                        </button>
                    </div>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-auto p-0 bg-gray-950/50">
                    {loading ? (
                        <div className="flex items-center justify-center h-64 text-gray-500">
                            加载中...
                        </div>
                    ) : error ? (
                        <div className="flex items-center justify-center h-64 text-red-400">
                            {error}
                        </div>
                    ) : (
                        <pre className="p-4 text-sm font-mono text-gray-300 whitespace-pre-wrap overflow-x-hidden">
                            {content}
                        </pre>
                    )}
                </div>

                {/* Footer */}
                <div className="p-4 border-t border-gray-800 bg-gray-900 rounded-b-xl flex justify-end">
                    <button
                        onClick={onClose}
                        className="px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white rounded transition-colors text-sm"
                    >
                        关闭
                    </button>
                </div>
            </div>
        </div>
    );
}
