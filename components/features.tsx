"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { 
  Shield, 
  MapPin, 
  QrCode, 
  Bell, 
  Zap, 
  Lock, 
  Users, 
  Clock, 
  AlertTriangle, 
  Smartphone,
  Route,
  CheckCircle,
  Play
} from "lucide-react";

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
    description: "Real-time push notifications for boarding, arrival, delays, and emergencies.",
  },
  {
    icon: Shield,
    title: "Anti-Fraud System",
    description: "Advanced detection of route deviations, unauthorized stops, and GPS spoofing.",
  },
  {
    icon: Zap,
    title: "Offline Resilience",
    description: "Continues tracking without network. Auto-syncs when connection returns.",
  },
  {
    icon: Lock,
    title: "End-to-End Security",
    description: "Military-grade encryption for all data. GDPR and privacy law compliant.",
  },
  {
    icon: Users,
    title: "Multi-User Access",
    description: "Role-based dashboards for schools, parents, and drivers.",
  },
  {
    icon: Clock,
    title: "ETA Predictions",
    description: "AI-powered arrival predictions accounting for traffic and weather.",
  },
  {
    icon: AlertTriangle,
    title: "Emergency Alerts",
    description: "One-tap SOS for drivers. Instant alerts to administrators.",
  },
  {
    icon: Smartphone,
    title: "Cross-Platform Apps",
    description: "Native iOS and Android apps. Web dashboard for schools.",
  },
  {
    icon: Route,
    title: "Smart Routes",
    description: "AI optimizes routes daily based on traffic patterns.",
  },
  {
    icon: CheckCircle,
    title: "Attendance Integration",
    description: "Automatic attendance marking. Syncs with school systems.",
  },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.06,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20, scale: 0.95 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      duration: 0.4,
      ease: "easeOut",
    },
  },
};

export function Features() {
  return (
    <section className="py-24 px-6 relative overflow-hidden bg-ebony transition-colors duration-300">
      {/* Background decoration */}
      <div className="absolute inset-0 opacity-30 pointer-events-none">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-gold/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-gold/5 rounded-full blur-3xl" />
      </div>

      <div className="max-w-7xl mx-auto relative z-10">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <motion.span 
            className="inline-block text-gold text-sm font-semibold tracking-wider uppercase mb-4 px-4 py-2 rounded-full bg-gold/10 border border-gold/20"
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
          >
            Core Features
          </motion.span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mt-4 text-foreground text-balance">
            Everything You Need for
            <span className="text-gold block mt-2">Complete Peace of Mind</span>
          </h2>
          <p className="text-muted mt-6 max-w-2xl mx-auto text-lg leading-relaxed text-pretty">
            A comprehensive suite of safety tools designed to keep every journey secure, 
            transparent, and worry-free.
          </p>
        </motion.div>

        {/* Features grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5"
        >
          {features.map((feature, index) => (
            <motion.div
              key={index}
              variants={itemVariants}
              whileHover={{ y: -5, transition: { duration: 0.2 } }}
              className="group relative"
            >
              <div className="h-full p-5 rounded-2xl bg-card border border-border hover:border-gold/50 transition-all duration-300 hover:shadow-lg hover:shadow-gold/5">
                {/* Icon container */}
                <motion.div
                  className="w-12 h-12 rounded-xl bg-gold/10 flex items-center justify-center mb-4 group-hover:bg-gold/20 transition-colors duration-300"
                  whileHover={{ scale: 1.1, rotate: 5 }}
                  transition={{ type: "spring", stiffness: 400, damping: 10 }}
                >
                  <feature.icon className="w-6 h-6 text-gold" />
                </motion.div>

                {/* Content */}
                <h3 className="text-lg font-semibold text-foreground mb-2 group-hover:text-gold transition-colors duration-300">
                  {feature.title}
                </h3>
                <p className="text-muted leading-relaxed text-sm">
                  {feature.description}
                </p>

                {/* Hover indicator */}
                <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-gold to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-b-2xl" />
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* CTA Button */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.3 }}
          className="text-center mt-16"
        >
          <p className="text-muted mb-6">
            See how SafePick transforms school transportation safety.
          </p>
          <Link href="/demo">
            <motion.button
              className="inline-flex items-center gap-3 px-8 py-4 bg-gold text-background font-semibold rounded-full hover:bg-gold-light transition-colors shadow-lg shadow-gold/20"
              whileHover={{ scale: 1.05, boxShadow: "0 20px 40px rgba(201, 146, 37, 0.3)" }}
              whileTap={{ scale: 0.95 }}
            >
              <Play className="w-5 h-5" />
              See Live in Action
            </motion.button>
          </Link>
        </motion.div>
      </div>
    </section>
  );
}
