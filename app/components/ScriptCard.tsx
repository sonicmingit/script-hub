'use client';

import { FileText, Copy, Terminal, Check, Eye, Trash2, Download } from "lucide-react";
import { useState, useEffect } from "react";
import { useLanguage } from "../context/LanguageContext";
import { ScriptViewerModal } from "./ScriptViewerModal";

interface ScriptCardProps {
    name: string;
    path: string;
    category: string;
    extension: string;
    size: number;
    updatedAt: string;
    description?: string;
    onDelete?: () => void;
}

export function ScriptCard({ script }: { script: ScriptCardProps }) {
    const { t } = useLanguage();
    const [copiedType, setCopiedType] = useState<'run' | 'save' | null>(null);
    const [showModal, setShowModal] = useState(false);

    const [origin, setOrigin] = useState('');

    useEffect(() => {
        setOrigin(window.location.origin);
    }, []);

    const getCopyCommand = () => {
        const url = `${origin}/api/raw/${script.path}`;
        if (script.extension === '.sh') {
            return `curl -sL ${url} | bash`;
        } else if (script.extension === '.py') {
            return `curl -sL ${url} | python3`;
        } else {
            return `wget ${url}`;
        }
    };

    const getDownloadCommand = () => {
        const url = `${origin}/api/raw/${script.path}`;
        return `curl -sL ${url} -o ${script.name}`;
    };

    const handleCopy = (type: 'run' | 'save') => {
        const cmd = type === 'run' ? getCopyCommand() : getDownloadCommand();

        const onSuccess = () => {
            setCopiedType(type);
            setTimeout(() => setCopiedType(null), 2000);
        };

        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(cmd)
                .then(onSuccess)
                .catch(() => fallbackCopyTextToClipboard(cmd, onSuccess));
        } else {
            fallbackCopyTextToClipboard(cmd, onSuccess);
        }
    };

    const fallbackCopyTextToClipboard = (text: string, onSuccess: () => void) => {
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
                onSuccess();
            }
        } catch (err) {
            console.error('Fallback copy failed', err);
        }

        document.body.removeChild(textArea);
    };

    const handleDelete = async () => {
        if (!confirm(`确定要删除脚本 "${script.name}" 吗?`)) return;

        try {
            const res = await fetch(`/api/scripts?path=${encodeURIComponent(script.path)}`, {
                method: 'DELETE'
            });
            if (res.ok) {
                window.location.reload();
            } else {
                alert('删除失败');
            }
        } catch (e) {
            alert('删除出错');
        }
    };

    return (
        <>
            <div className="bg-gray-900 border border-gray-800 rounded-lg p-5 hover:border-gray-700 transition-all group flex flex-col h-full">
                <div className="flex justify-between items-start mb-4">
                    <div className="p-2 bg-gray-800 rounded-lg group-hover:bg-blue-900/20 group-hover:text-blue-400 transition-colors">
                        <FileText size={24} />
                    </div>
                    <div className="flex gap-2 items-center">
                        <span className="text-xs text-gray-500 bg-gray-950 px-2 py-1 rounded border border-gray-800">
                            {script.extension}
                        </span>
                        <button
                            onClick={(e) => { e.stopPropagation(); handleDelete(); }}
                            className="p-1.5 text-gray-600 hover:text-red-500 hover:bg-red-900/20 rounded opacity-0 group-hover:opacity-100 transition-all"
                            title="删除脚本"
                        >
                            <Trash2 size={16} />
                        </button>
                    </div>
                </div>

                <h3 className="text-lg font-semibold text-gray-200 mb-1 truncate" title={script.name}>
                    {script.name}
                </h3>
                {script.description && (
                    <div className="mb-2 h-10 overflow-hidden">
                        <p className="text-sm text-gray-400 line-clamp-2" title={script.description}>
                            {script.description}
                        </p>
                    </div>
                )}
                <p className="text-xs text-gray-500 mb-4 mt-auto">
                    {script.category} • {(script.size / 1024).toFixed(1)} KB
                </p>

                <div className="bg-gray-950 rounded p-3 font-mono text-xs text-gray-400 mb-3 overflow-x-auto whitespace-nowrap border border-gray-900">
                    {getCopyCommand()}
                </div>

                <div className="grid grid-cols-3 gap-2 mt-auto">
                    <button
                        onClick={() => setShowModal(true)}
                        className="flex items-center justify-center gap-1.5 py-2 rounded-md bg-gray-800 hover:bg-gray-700 text-sm font-medium transition-colors text-blue-400 hover:text-white border border-gray-700 hover:border-gray-600"
                    >
                        <Eye size={14} />
                        <span className="hidden sm:inline">查看</span>
                    </button>
                    <button
                        onClick={() => handleCopy('run')}
                        disabled={!origin}
                        className="flex items-center justify-center gap-1.5 py-2 rounded-md bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        title="复制运行命令"
                    >
                        {copiedType === 'run' ? <Check size={14} /> : <Copy size={14} />}
                        <span className="hidden sm:inline">{copiedType === 'run' ? "已复制" : "运行"}</span>
                    </button>
                    <button
                        onClick={() => handleCopy('save')}
                        disabled={!origin}
                        className="flex items-center justify-center gap-1.5 py-2 rounded-md bg-purple-600 hover:bg-purple-500 text-white text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        title="复制下载命令"
                    >
                        {copiedType === 'save' ? <Check size={14} /> : <Download size={14} />}
                        <span className="hidden sm:inline">{copiedType === 'save' ? "已复制" : "下载"}</span>
                    </button>
                </div>
            </div>

            <ScriptViewerModal
                isOpen={showModal}
                onClose={() => setShowModal(false)}
                scriptPath={script.path}
                scriptName={script.name}
            />
        </>
    );
}
