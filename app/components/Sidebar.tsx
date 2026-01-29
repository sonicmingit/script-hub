import { getAllScripts } from "@/lib/file-system";
import { SidebarClient } from "./SidebarClient";

export async function Sidebar() {
    const categories = getAllScripts();

    // Serialize dates or complex objects if necessary (Next.js warns about Dates passed to Client Components)
    // Our getAllScripts returns 'Date' object for updatedAt. We need to convert it?
    // SidebarClient interface uses 'size' etc but let's check what I defined.
    // I defined a local interface in SidebarClient that matches basic structure.
    // Let's just pass it. New Next.js might handle it or we convert.
    // To be safe, JSONify.

    const serializedData = JSON.parse(JSON.stringify(categories));

    return <SidebarClient categories={serializedData} />;
}
