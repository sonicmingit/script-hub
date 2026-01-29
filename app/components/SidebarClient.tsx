'use client';

import { Folder, Terminal, FileCode, Plus } from "lucide-react";
import Link from "next/link";
import { useLanguage } from "../context/LanguageContext";
import { Category } from "@/lib/file-system"; // Ensure this type is exported or redefine

// Re-define if not easy to import from lib (since lib is server-side mostly, but types are shared)
// Actually we can import types from lib/file-system.ts safe in client if it doesn't import fs.
// Wait, lib/file-system.ts imports 'fs'. Importing it in client component might break build?
// Let's check. imports are usually tree-shaken but 'fs' is dangerous.
// Better to define type locally or in a shared types file. 
// For now, I'll copy the type interface to avoid 'fs' import issues in Client Component.

interface ScriptFile {
    name: string;
    path: string;
    category: string;
    extension: string;
    size: number;
}
interface SidebarCategory {
    name: string;
    scripts: ScriptFile[];
}

export function SidebarClient({ categories }: { categories: SidebarCategory[] }) {
    const { t } = useLanguage();

    return (
        <aside className="w-64 bg-gray-900 text-gray-100 border-r border-gray-800 flex flex-col h-full">
            <div className="p-4 border-b border-gray-800 flex justify-between items-center">
                <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent flex items-center gap-2">
                    <Terminal className="text-blue-400" size={24} />
                    {t('app.title')}
                </h1>
                <div className="flex gap-2">
                    <Link href="/add" title={t('sidebar.add')} className="text-gray-400 hover:text-white transition-colors bg-gray-800 p-1 rounded hover:bg-gray-700 flex items-center justify-center w-7 h-7">
                        <Plus size={16} />
                    </Link>
                </div>
            </div>
            <nav className="flex-1 overflow-y-auto p-4 space-y-2">
                {/* All Scripts Link */}
                <Link
                    href="/"
                    className="flex items-center gap-2 text-sm font-semibold text-gray-300 hover:text-white hover:bg-gray-800 px-3 py-2 rounded transition-colors mb-4"
                >
                    <Folder size={16} className="text-blue-400" />
                    {t('home.all_scripts')}
                </Link>

                {categories.map((category) => (
                    <CollapsibleCategory key={category.name} category={category} />
                ))}

                {categories.length === 0 && (
                    <div className="text-sm text-gray-500 text-center py-4">
                        {t('sidebar.empty')}
                    </div>
                )}
            </nav>
            <div className="p-4 border-t border-gray-800">
                <div className="text-xs text-center text-gray-500">
                    {t('sidebar.version')}
                </div>
            </div>
        </aside>
    );
}

import { ChevronRight, ChevronDown } from "lucide-react";
import { useState } from "react";

function CollapsibleCategory({ category }: { category: SidebarCategory }) {
    const [isOpen, setIsOpen] = useState(true);

    return (
        <div>
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full flex items-center gap-2 px-2 py-1.5 text-xs font-semibold text-gray-500 uppercase tracking-wider hover:text-gray-300 transition-colors"
            >
                {isOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                {category.name}
                <span className="ml-auto bg-gray-800 text-gray-400 px-1.5 py-0.5 rounded text-[10px]">
                    {category.scripts.length}
                </span>
            </button>

            {isOpen && (
                <ul className="space-y-1 mt-1 pl-2 border-l border-gray-800 ml-3">
                    {category.scripts.map((script) => (
                        <li key={script.path}>
                            <Link
                                href={`/?category=${encodeURIComponent(category.name)}`}
                                className="block px-3 py-2 text-sm text-gray-300 hover:text-white hover:bg-gray-800 rounded transition-colors truncate flex items-center gap-2"
                                title={script.name}
                            >
                                <FileCode size={14} className="text-gray-500" />
                                {script.name}
                            </Link>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}
