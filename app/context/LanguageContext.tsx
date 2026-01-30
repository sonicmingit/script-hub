'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';

type Language = 'en' | 'cn';

type Translations = {
    [key in Language]: {
        [key: string]: string;
    };
};

const translations: Translations = {
    en: {
        // Sidebar
        'app.title': 'Script Hub',
        'sidebar.loading': 'Loading categories...',
        'sidebar.empty': 'No scripts found',
        'sidebar.version': 'Private Script Hub v1.0',
        'sidebar.add': 'Add Script',

        // Home
        'home.all_scripts': 'All Scripts',
        'home.category': 'Category: ',
        'home.count': ' scripts available',
        'home.empty.title': 'No scripts found',
        'home.empty.desc': 'Please add files to data/scripts',

        // Script Card
        'card.copy': 'Copy Command',
        'card.copied': 'Copied',

        // Add Page
        'add.title': 'Add Script',
        'add.mode.create': 'New Script',
        'add.mode.upload': 'Upload File',
        'add.field.category': 'Category (Optional)',
        'add.field.category.placeholder': 'e.g., utils',
        'add.field.filename': 'Filename',
        'add.field.filename.placeholder': 'example.sh',
        'add.field.filename.upload_placeholder': 'Defaults to uploaded filename',
        'add.field.content': 'Script Content',
        'add.field.file': 'Select File',
        'add.field.file.placeholder': 'Click or drag file here',
        'add.btn.save': 'Save Script',
        'add.btn.saving': 'Saving...',
        'add.error.file_content': 'Please select a file or enter content',
        'add.success': 'Saved successfully',

        // Login
        'login.title': 'Script Hub Login',
        'login.username': 'Username',
        'login.password': 'Password',
        'login.btn': 'Login',
        'login.btn.loading': 'Logging in...',
        'login.error': 'Login failed: Invalid credentials',

        // Common
        'common.error': 'An error occurred',
    },
    cn: {
        // Sidebar
        'app.title': '脚本仓库',
        'sidebar.loading': '加载分类中...',
        'sidebar.empty': '暂无脚本',
        'sidebar.version': 'Private Script Hub v1.0',
        'sidebar.add': '添加脚本',

        // Home
        'home.all_scripts': '所有脚本',
        'home.category': '分类: ',
        'home.count': ' 个脚本可用',
        'home.empty.title': '暂无脚本',
        'home.empty.desc': '请将文件放入 data/scripts 目录',
        'home.server_cmd_title': '服务器一键管理命令',
        'home.server_cmd_desc': '在任意终端执行此命令，即可获取脚本列表并一键运行',
        'home.save_cmd_title': '一键保存脚本到本地',
        'home.save_cmd_desc': '下载仓库中所有脚本为 ZIP 压缩包并自动解压',

        // Script Card
        'card.copy': '复制命令',
        'card.copied': '已复制',

        // Add Page
        'add.title': '添加脚本',
        'add.mode.create': '新建脚本',
        'add.mode.upload': '上传文件',
        'add.field.category': '分类目录 (可选)',
        'add.field.category.placeholder': '例如: utils',
        'add.field.filename': '文件名',
        'add.field.filename.placeholder': 'example.sh',
        'add.field.filename.upload_placeholder': '默认使用上传文件名',
        'add.field.content': '脚本内容',
        'add.field.file': '选择文件',
        'add.field.file.placeholder': '点击或拖拽文件到这里',
        'add.btn.save': '保存脚本',
        'add.btn.saving': '保存中...',
        'add.error.file_content': '请选择文件或输入内容',
        'add.success': '保存成功',

        // Login
        'login.title': 'Script Hub 登录',
        'login.username': '用户名',
        'login.password': '密码',
        'login.btn': '登 录',
        'login.btn.loading': '登录中...',
        'login.error': '登录失败：用户名或密码错误',

        // Common
        'common.error': '发生错误',
    }
};

interface LanguageContextType {
    language: Language;
    setLanguage: (lang: Language) => void;
    t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export function LanguageProvider({ children }: { children: React.ReactNode }) {
    const [language, setLanguage] = useState<Language>('cn'); // Default to Chinese

    useEffect(() => {
        // Enforce Chinese
        setLanguage('cn');
        localStorage.setItem('app_language', 'cn');
    }, []);

    const handleSetLanguage = (lang: Language) => {
        // No-op or allow if needed in future, but for now enforcing CN
        setLanguage('cn');
    };

    const t = (key: string) => {
        return translations['cn'][key] || key;
    };

    return (
        <LanguageContext.Provider value={{ language: 'cn', setLanguage: handleSetLanguage, t }}>
            {children}
        </LanguageContext.Provider>
    );
}

export function useLanguage() {
    const context = useContext(LanguageContext);
    if (context === undefined) {
        throw new Error('useLanguage must be used within a LanguageProvider');
    }
    return context;
}
