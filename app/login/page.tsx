'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Terminal, Lock } from "lucide-react";
import { useLanguage } from '../context/LanguageContext';

export default function LoginPage() {
    const { t } = useLanguage();
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const res = await fetch('/api/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password }),
            });

            if (res.ok) {
                // Force hard reload to update middleware state
                window.location.href = '/';
            } else {
                setError(t('login.error'));
            }
        } catch (err) {
            setError(t('common.error'));
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-black flex flex-col items-center justify-center p-4">
            <div className="w-full max-w-md bg-gray-900 border border-gray-800 rounded-lg p-8 shadow-2xl">
                <div className="flex justify-center mb-6">
                    <div className="p-3 bg-gray-800 rounded-full text-blue-400">
                        <Terminal size={32} />
                    </div>
                </div>

                <h2 className="text-2xl font-bold text-center text-white mb-8">
                    {t('login.title')}
                </h2>

                <form onSubmit={handleSubmit} className="space-y-6">
                    {error && (
                        <div className="bg-red-900/30 border border-red-800 text-red-200 text-sm p-3 rounded text-center">
                            {error}
                        </div>
                    )}

                    <div>
                        <label className="block text-sm font-medium text-gray-400 mb-2">
                            {t('login.username')}
                        </label>
                        <input
                            type="text"
                            required
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            className="w-full bg-gray-950 border border-gray-800 rounded px-4 py-2 text-white focus:outline-none focus:border-blue-500 transition-colors"
                            placeholder="Env User (def: admin)"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-400 mb-2">
                            {t('login.password')}
                        </label>
                        <input
                            type="password"
                            required
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="w-full bg-gray-950 border border-gray-800 rounded px-4 py-2 text-white focus:outline-none focus:border-blue-500 transition-colors"
                            placeholder="Env Password"
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-3 rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center gap-2"
                    >
                        <Lock size={18} />
                        {loading ? t('login.btn.loading') : t('login.btn')}
                    </button>
                </form>
            </div>
        </div>
    );
}
