"use client";

import { motion } from "framer-motion";
import { Shield, MapPin, QrCode, Bell, Zap, Lock } from "lucide-react";

const features = [
  {
    icon: MapPin,
    title: "Live GPS Tracking",
    description: "Track every vehicle in real-time with precision accuracy down to 5 meters.",
  },
  {
    icon: QrCode,
    title: "QR Verification",
    description: "Secure pickup/drop confirmation that can only be scanned within geofenced zones.",
  },
  {
    icon: Bell,
    title: "Instant Notifications",
    description: "Get real-time push notifications for every event - boarding, arrival, delays.",
  },
  {
    icon: Shield,
    title: "Anti-Fraud System",
    description: "Advanced detection of route deviations, unauthorized stops, and suspicious patterns.",
  },
  {
    icon: Zap,
    title: "Offline Resilience",
    description: "Continues tracking even without network. Auto-syncs when connectivity returns.",
  },
  {
    icon: Lock,
    title: "End-to-End Security",
    description: "Military-grade encryption for all data. GDPR and local privacy compliant.",
  },
];

export function Features() {
  return (
    <section className="py-24 px-6 relative overflow-hidden">
      <div className="max-w-7xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="text-gold text-sm font-semibold tracking-wider uppercase">
            Core Features
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mt-4 text-foreground">
            Everything You Need
          </h2>
          <p className="text-muted mt-4 max-w-2xl mx-auto text-balance">
            A comprehensive suite of tools designed for complete peace of mind.
          </p>
        </motion.div>

        {/* Features grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              className="group p-6 rounded-2xl bg-ebony-light border border-border hover:border-gold/50 transition-all"
            >
              <motion.div
                className="w-14 h-14 rounded-2xl bg-gold/10 flex items-center justify-center mb-4 group-hover:bg-gold/20 transition-colors"
                whileHover={{ rotate: [0, -10, 10, 0] }}
                transition={{ duration: 0.5 }}
              >
                <feature.icon className="w-7 h-7 text-gold" />
              </motion.div>
              <h3 className="text-xl font-semibold text-foreground mb-2">{feature.title}</h3>
              <p className="text-muted leading-relaxed">{feature.description}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
