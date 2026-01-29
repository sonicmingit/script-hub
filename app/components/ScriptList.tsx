'use client';

import { ScriptCard } from "./ScriptCard";
import { useLanguage } from "../context/LanguageContext";
import { useEffect, useState } from "react";
import { Copy, Check, Terminal } from "lucide-react";

interface ScriptListProps {
    selectedCategory?: string;
    scripts: any[];
}

export function ScriptList({ selectedCategory, scripts }: ScriptListProps) {
    const { t } = useLanguage();
    const [serverCmd, setServerCmd] = useState('');
    const [copied, setCopied] = useState(false);

    useEffect(() => {
        setServerCmd(`curl -sL ${window.location.origin}/script | bash`);
    }, []);

    const handleCopy = () => {
        if (!serverCmd) return;

        // 尝试使用最新的 Clipboard API
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(serverCmd).then(() => {
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            }).catch(() => fallbackCopy(serverCmd));
        } else {
            fallbackCopy(serverCmd);
        }
    };

    const fallbackCopy = (text: string) => {
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.position = "fixed";
        textArea.style.left = "-9999px";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        try {
            document.execCommand('copy');
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        } catch (err) {
            console.error('Copy failed', err);
        }
        document.body.removeChild(textArea);
    };

    return (
        <div className="space-y-8">
            {/* Server Command Banner */}
            {!selectedCategory && (
                <div className="bg-gradient-to-r from-gray-900 to-gray-800 border border-gray-700 rounded-lg p-6 shadow-lg relative overflow-hidden group">
                    <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                        <Terminal size={120} />
                    </div>

                    <div className="relative z-10">
                        <h3 className="text-lg font-bold text-blue-400 mb-2 flex items-center gap-2">
                            <Terminal size={20} />
                            {t('home.server_cmd_title')}
                        </h3>
                        <p className="text-gray-400 text-sm mb-4">
                            {t('home.server_cmd_desc')}
                        </p>

                        <div className="flex items-center gap-2 bg-black/50 p-3 rounded border border-gray-700 font-mono text-sm text-green-400 max-w-2xl">
                            <span className="flex-1 truncate select-all">{serverCmd || 'Loading...'}</span>
                            <button
                                onClick={handleCopy}
                                className="text-gray-400 hover:text-white transition-colors p-1"
                                title={t('card.copy')}
                            >
                                {copied ? <Check size={16} className="text-green-500" /> : <Copy size={16} />}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            <div className="flex justify-between items-center">
                <div>
                    <h2 className="text-2xl font-bold text-white mb-2">
                        {selectedCategory ? `${t('home.category')}${selectedCategory}` : t('home.all_scripts')}
                    </h2>
                    <p className="text-gray-400">
                        {scripts.length}{t('home.count')}
                    </p>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {scripts.map((script) => (
                    <ScriptCard
                        key={script.path}
                        script={script}
                    />
                ))}

                {scripts.length === 0 && (
                    <div className="col-span-full text-center py-20 bg-gray-900/50 rounded-xl border border-gray-800 border-dashed">
                        <p className="text-gray-500">{t('home.empty.title')}</p>
                        <p className="text-gray-600 text-sm mt-2">{t('home.empty.desc')}</p>
                    </div>
                )}
            </div>
        </div>
    );
}
