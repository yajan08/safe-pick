import { Navbar } from "@/components/navbar";
import { HeroSection } from "@/components/hero-section";
import { TripSimulator } from "@/components/trip-simulator";
import { Features } from "@/components/features";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-background">
      <Navbar />
      <HeroSection />
      <TripSimulator />
      <Features />
      <Footer />
    </main>
  );
}
