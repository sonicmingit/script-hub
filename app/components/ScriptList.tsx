'use client';

import { ScriptCard } from "./ScriptCard";
import { useLanguage } from "../context/LanguageContext";

interface ScriptListProps {
    selectedCategory?: string;
    scripts: any[];
}

export function ScriptList({ selectedCategory, scripts }: ScriptListProps) {
    const { t } = useLanguage();

    return (
        <div className="space-y-8">
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
