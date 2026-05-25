"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { ArrowLeft, Play } from "lucide-react";
import { Navbar } from "@/components/navbar";
import { Footer } from "@/components/footer";

export default function DemoPage() {
  return (
    <main className="min-h-screen bg-background transition-colors duration-300">
      <Navbar />
      
      <section className="pt-32 pb-24 px-6">
        <div className="max-w-5xl mx-auto">
          {/* Back link */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4 }}
          >
            <Link 
              href="/" 
              className="inline-flex items-center gap-2 text-muted hover:text-gold transition-colors mb-8"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to Home
            </Link>
          </motion.div>

          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <motion.span 
              className="inline-block text-gold text-sm font-semibold tracking-wider uppercase mb-4 px-4 py-2 rounded-full bg-gold/10 border border-gold/20"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2 }}
            >
              Live Demo
            </motion.span>
            <h1 className="text-3xl md:text-4xl lg:text-5xl font-bold text-foreground text-balance">
              See SafePick in Action
            </h1>
            <p className="text-muted mt-4 max-w-2xl mx-auto text-lg leading-relaxed">
              Watch how SafePick transforms school transportation safety with real-time tracking and verified confirmations.
            </p>
          </motion.div>

          {/* Video placeholder */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="relative"
          >
            <div className="aspect-video rounded-2xl bg-card border border-border overflow-hidden shadow-2xl shadow-gold/10">
              {/* Placeholder content */}
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-gradient-to-br from-ebony to-card">
                {/* Animated background elements */}
                <div className="absolute inset-0 overflow-hidden">
                  <motion.div
                    className="absolute top-1/4 left-1/4 w-64 h-64 bg-gold/5 rounded-full blur-3xl"
                    animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.5, 0.3] }}
                    transition={{ duration: 4, repeat: Infinity }}
                  />
                  <motion.div
                    className="absolute bottom-1/4 right-1/4 w-48 h-48 bg-gold/10 rounded-full blur-2xl"
                    animate={{ scale: [1.2, 1, 1.2], opacity: [0.5, 0.3, 0.5] }}
                    transition={{ duration: 4, repeat: Infinity, delay: 2 }}
                  />
                </div>

                {/* Play button */}
                <motion.div
                  className="relative z-10 w-24 h-24 rounded-full bg-gold/20 border-2 border-gold/50 flex items-center justify-center cursor-pointer group"
                  whileHover={{ scale: 1.1, borderColor: "rgba(201, 146, 37, 0.8)" }}
                  whileTap={{ scale: 0.95 }}
                  animate={{ 
                    boxShadow: [
                      "0 0 0 0 rgba(201, 146, 37, 0.4)",
                      "0 0 0 20px rgba(201, 146, 37, 0)",
                    ]
                  }}
                  transition={{
                    boxShadow: { duration: 1.5, repeat: Infinity },
                  }}
                >
                  <Play className="w-10 h-10 text-gold ml-1" fill="currentColor" />
                </motion.div>

                {/* Coming soon text */}
                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  className="mt-8 text-muted text-center relative z-10"
                >
                  <span className="text-gold font-medium">Demo video coming soon</span>
                  <br />
                  <span className="text-sm">Full product walkthrough</span>
                </motion.p>
              </div>

              {/* Video element placeholder for future */}
              {/* <video className="w-full h-full object-cover" controls>
                <source src="/demo-video.mp4" type="video/mp4" />
              </video> */}
            </div>

            {/* Decorative border glow */}
            <div className="absolute -inset-0.5 bg-gradient-to-r from-gold/20 via-transparent to-gold/20 rounded-2xl -z-10 blur-sm" />
          </motion.div>

          {/* Features preview */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="mt-16 grid sm:grid-cols-3 gap-6"
          >
            {[
              { title: "Real-Time Tracking", desc: "Live GPS location updates" },
              { title: "QR Verification", desc: "Secure pickup confirmation" },
              { title: "Instant Alerts", desc: "Push notifications for events" },
            ].map((item, index) => (
              <motion.div
                key={index}
                className="p-6 rounded-xl bg-card border border-border text-center"
                whileHover={{ y: -5, borderColor: "rgba(201, 146, 37, 0.5)" }}
                transition={{ duration: 0.2 }}
              >
                <h3 className="text-lg font-semibold text-foreground mb-2">{item.title}</h3>
                <p className="text-sm text-muted">{item.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
