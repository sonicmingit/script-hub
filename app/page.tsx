import { getAllScripts } from "@/lib/file-system";
import { ScriptList } from "./components/ScriptList";

export const dynamic = 'force-dynamic';

export default async function Home({
  searchParams,
}: {
  searchParams: Promise<{ category?: string }>;
}) {
  const sp = await searchParams;
  const categories = getAllScripts();
  const selectedCategory = sp.category;

  // Flatten scripts if no category selected, or filter by category
  let scriptsDisplay = [];

  if (selectedCategory) {
    const category = categories.find(c => c.name === selectedCategory);
    scriptsDisplay = category ? category.scripts : [];
  } else {
    scriptsDisplay = categories.flatMap(c => c.scripts);
  }

  // Pass data to Client Component which handles i18n
  // We need to ensure dates are strings for Client Components
  const serializedScripts = JSON.parse(JSON.stringify(scriptsDisplay));

  return (
    <ScriptList
      selectedCategory={selectedCategory}
      scripts={serializedScripts}
    />
  );
}
