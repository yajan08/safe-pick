import { Navbar } from "@/components/navbar";
import { HeroSection } from "@/components/hero-section";
import { Features } from "@/components/features";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-background transition-colors duration-300">
      <Navbar />
      <HeroSection />
      <Features />
      <Footer />
    </main>
  );
}
