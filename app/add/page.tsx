'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Upload, FileText, ArrowLeft, Save } from 'lucide-react';
import Link from 'next/link';
import { useLanguage } from '../context/LanguageContext';

export default function AddScriptPage() {
    const { t } = useLanguage();
    const router = useRouter();
    const [mode, setMode] = useState<'upload' | 'create'>('create');
    const [category, setCategory] = useState('');
    const [filename, setFilename] = useState('');
    const [content, setContent] = useState('');
    const [file, setFile] = useState<File | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        const formData = new FormData();
        formData.append('category', category);
        formData.append('filename', filename);

        if (mode === 'create') {
            formData.append('content', content);
        } else if (file) {
            formData.append('file', file);
            // If filename not provided, use uploaded filename
            if (!filename) {
                formData.set('filename', file.name);
            }
        } else {
            setError(t('add.error.file_content'));
            setLoading(false);
            return;
        }

        try {
            const res = await fetch('/api/scripts', {
                method: 'POST',
                body: formData,
            });

            if (res.ok) {
                router.push('/');
                router.refresh();
            } else {
                const data = await res.json();
                setError(data.error || t('common.error'));
            }
        } catch (err) {
            setError(t('common.error'));
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="max-w-2xl mx-auto">
            <div className="mb-6 flex items-center gap-4">
                <Link href="/" className="p-2 hover:bg-gray-800 rounded-full text-gray-400 hover:text-white transition-colors">
                    <ArrowLeft size={20} />
                </Link>
                <h1 className="text-2xl font-bold text-white">{t('add.title')}</h1>
            </div>

            <div className="bg-gray-900 border border-gray-800 rounded-lg p-6">
                <div className="flex gap-4 mb-6 border-b border-gray-800 pb-4">
                    <button
                        onClick={() => setMode('create')}
                        className={`flex items-center gap-2 px-4 py-2 rounded transition-colors ${mode === 'create' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}
                    >
                        <FileText size={18} />
                        {t('add.mode.create')}
                    </button>
                    <button
                        onClick={() => setMode('upload')}
                        className={`flex items-center gap-2 px-4 py-2 rounded transition-colors ${mode === 'upload' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}
                    >
                        <Upload size={18} />
                        {t('add.mode.upload')}
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    {error && (
                        <div className="bg-red-900/30 border border-red-800 text-red-200 p-3 rounded">
                            {error}
                        </div>
                    )}

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-400 mb-2">{t('add.field.category')}</label>
                            <input
                                type="text"
                                value={category}
                                onChange={e => setCategory(e.target.value)}
                                placeholder={t('add.field.category.placeholder')}
                                className="w-full bg-gray-950 border border-gray-800 rounded px-3 py-2 text-white focus:outline-none focus:border-blue-500"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-400 mb-2">{t('add.field.filename')}</label>
                            <input
                                type="text"
                                value={filename}
                                onChange={e => setFilename(e.target.value)}
                                placeholder={mode === 'upload' ? t('add.field.filename.upload_placeholder') : t('add.field.filename.placeholder')}
                                required={mode === 'create'}
                                className="w-full bg-gray-950 border border-gray-800 rounded px-3 py-2 text-white focus:outline-none focus:border-blue-500"
                            />
                        </div>
                    </div>

                    {mode === 'create' ? (
                        <div>
                            <label className="block text-sm font-medium text-gray-400 mb-2">{t('add.field.content')}</label>
                            <textarea
                                value={content}
                                onChange={e => setContent(e.target.value)}
                                required
                                rows={10}
                                className="w-full bg-gray-950 border border-gray-800 rounded px-3 py-2 text-white font-mono text-sm focus:outline-none focus:border-blue-500"
                            />
                        </div>
                    ) : (
                        <div>
                            <label className="block text-sm font-medium text-gray-400 mb-2">{t('add.field.file')}</label>
                            <div className="border-2 border-dashed border-gray-800 rounded-lg p-8 text-center hover:border-blue-500 transition-colors cursor-pointer bg-gray-950 relative">
                                <input
                                    type="file"
                                    className="absolute inset-0 opacity-0 cursor-pointer"
                                    onChange={e => setFile(e.target.files?.[0] || null)}
                                />
                                <Upload size={32} className="mx-auto text-gray-500 mb-2" />
                                <p className="text-gray-400 text-sm">
                                    {file ? file.name : t('add.field.file.placeholder')}
                                </p>
                            </div>
                        </div>
                    )}

                    <div className="pt-4">
                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-green-600 hover:bg-green-500 text-white font-bold py-3 rounded transition-colors flex justify-center items-center gap-2"
                        >
                            <Save size={18} />
                            {loading ? t('add.btn.saving') : t('add.btn.save')}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
