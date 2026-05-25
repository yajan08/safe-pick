import { Navbar } from "@/components/navbar";
import { HeroSection } from "@/components/hero-section";
import { Features } from "@/components/features";
import { DualPerspective } from "@/components/dual-perspective";
import { EdgeCases } from "@/components/edge-cases";
import { Pricing } from "@/components/pricing";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-background">
      <Navbar />
      <HeroSection />
      <Features />
      <DualPerspective />
      <EdgeCases />
      <Pricing />
      <Footer />
    </main>
  );
}
