"use client";

import { motion } from "framer-motion";
import { Navbar } from "@/components/navbar";
import { Footer } from "@/components/footer";
import { Shield, Users, Target, Heart } from "lucide-react";

const values = [
  {
    icon: Shield,
    title: "Safety First",
    description: "Every feature we build starts with one question: Does this make children safer?",
  },
  {
    icon: Users,
    title: "Community Trust",
    description: "We work hand-in-hand with schools and parents to build systems that work for everyone.",
  },
  {
    icon: Target,
    title: "Precision",
    description: "Real-time tracking with anti-cheat measures ensures accurate, reliable information.",
  },
  {
    icon: Heart,
    title: "Peace of Mind",
    description: "Parents deserve to know their children are safe. We make that possible.",
  },
];

export default function AboutPage() {
  return (
    <main className="min-h-screen bg-background">
      <Navbar />
      
      <section className="pt-32 pb-20 px-6">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="text-center mb-16"
          >
            <h1 className="text-4xl md:text-5xl font-bold text-foreground mb-6">
              About <span className="text-gold">SafePick</span>
            </h1>
            <p className="text-xl text-muted max-w-2xl mx-auto leading-relaxed">
              We&apos;re building the future of school transport safety, one verified trip at a time.
            </p>
          </motion.div>

          {/* Story */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="prose prose-invert max-w-none mb-20"
          >
            <div className="p-8 rounded-2xl glass border border-gold/20">
              <h2 className="text-2xl font-bold text-foreground mb-4">Our Story</h2>
              <p className="text-muted leading-relaxed mb-4">
                SafePick was born from a simple observation: parents spend countless hours worrying about their children&apos;s safety during school commutes. Traditional methods of communication were unreliable, and there was no way to verify that a child had actually boarded the right vehicle.
              </p>
              <p className="text-muted leading-relaxed">
                We set out to change that. Using QR-based verification, real-time GPS tracking, and instant notifications, we&apos;ve created a system where parents always know exactly where their children are. No more uncertainty. No more worry. Just peace of mind.
              </p>
            </div>
          </motion.div>

          {/* Values */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
          >
            <h2 className="text-2xl font-bold text-foreground text-center mb-12">Our Values</h2>
            <div className="grid md:grid-cols-2 gap-6">
              {values.map((value, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.5 + index * 0.1 }}
                  className="p-6 rounded-xl glass border border-gold/10 hover:border-gold/30 transition-colors"
                >
                  <div className="w-12 h-12 rounded-xl bg-gold/10 flex items-center justify-center mb-4">
                    <value.icon className="w-6 h-6 text-gold" />
                  </div>
                  <h3 className="text-lg font-semibold text-foreground mb-2">{value.title}</h3>
                  <p className="text-muted text-sm leading-relaxed">{value.description}</p>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
