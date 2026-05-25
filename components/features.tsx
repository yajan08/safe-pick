"use client";

import { motion } from "framer-motion";
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
  CheckCircle
} from "lucide-react";

const features = [
  {
    icon: MapPin,
    title: "Live GPS Tracking",
    description: "Track every vehicle in real-time with precision accuracy down to 5 meters. Parents can see exactly where their child is at any moment.",
  },
  {
    icon: QrCode,
    title: "QR Verification",
    description: "Secure pickup/drop confirmation that can only be scanned within geofenced zones. Ensures only authorized pickups.",
  },
  {
    icon: Bell,
    title: "Instant Notifications",
    description: "Get real-time push notifications for every event - boarding, arrival, delays, route changes, and emergencies.",
  },
  {
    icon: Shield,
    title: "Anti-Fraud System",
    description: "Advanced detection of route deviations, unauthorized stops, suspicious patterns, and GPS spoofing attempts.",
  },
  {
    icon: Zap,
    title: "Offline Resilience",
    description: "Continues tracking even without network connectivity. Auto-syncs all data when connection returns.",
  },
  {
    icon: Lock,
    title: "End-to-End Security",
    description: "Military-grade encryption for all data transmissions. Fully GDPR and local privacy law compliant.",
  },
  {
    icon: Users,
    title: "Multi-User Access",
    description: "Schools, parents, and drivers all have role-based dashboards with appropriate permissions and views.",
  },
  {
    icon: Clock,
    title: "ETA Predictions",
    description: "AI-powered arrival time predictions that account for traffic, weather, and historical patterns.",
  },
  {
    icon: AlertTriangle,
    title: "Emergency Alerts",
    description: "One-tap SOS button for drivers. Instant alerts to school administrators and emergency contacts.",
  },
  {
    icon: Smartphone,
    title: "Cross-Platform Apps",
    description: "Native iOS and Android apps for parents. Web dashboard for schools. Driver app with offline support.",
  },
  {
    icon: Route,
    title: "Smart Route Optimization",
    description: "AI optimizes routes daily based on traffic patterns, reducing travel time and fuel costs.",
  },
  {
    icon: CheckCircle,
    title: "Attendance Integration",
    description: "Automatic attendance marking when students board/exit. Syncs with school management systems.",
  },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.5,
      ease: "easeOut",
    },
  },
};

export function Features() {
  return (
    <section className="py-24 px-6 relative overflow-hidden bg-ebony">
      {/* Background decoration */}
      <div className="absolute inset-0 opacity-30">
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
          className="text-center mb-20"
        >
          <motion.span 
            className="inline-block text-gold text-sm font-semibold tracking-wider uppercase mb-4 px-4 py-2 rounded-full bg-gold/10 border border-gold/20"
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
          >
            Core Features
          </motion.span>
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mt-6 text-foreground text-balance">
            Everything You Need for
            <span className="text-gold block mt-2">Complete Peace of Mind</span>
          </h2>
          <p className="text-muted mt-6 max-w-2xl mx-auto text-lg leading-relaxed text-pretty">
            A comprehensive suite of safety tools designed to keep every journey secure, 
            transparent, and worry-free for parents, schools, and drivers alike.
          </p>
        </motion.div>

        {/* Features grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
        >
          {features.map((feature, index) => (
            <motion.div
              key={index}
              variants={itemVariants}
              className="group relative"
            >
              <div className="h-full p-6 rounded-2xl bg-card border border-border hover:border-gold/50 transition-all duration-300 hover:shadow-lg hover:shadow-gold/5">
                {/* Icon container */}
                <motion.div
                  className="w-14 h-14 rounded-2xl bg-gold/10 flex items-center justify-center mb-5 group-hover:bg-gold/20 transition-colors duration-300"
                  whileHover={{ scale: 1.1, rotate: 5 }}
                  transition={{ type: "spring", stiffness: 400, damping: 10 }}
                >
                  <feature.icon className="w-7 h-7 text-gold" />
                </motion.div>

                {/* Content */}
                <h3 className="text-xl font-semibold text-foreground mb-3 group-hover:text-gold transition-colors duration-300">
                  {feature.title}
                </h3>
                <p className="text-muted leading-relaxed text-sm">
                  {feature.description}
                </p>

                {/* Hover indicator */}
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-gold to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-b-2xl" />
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Bottom CTA */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5 }}
          className="text-center mt-16"
        >
          <p className="text-muted mb-6">
            And many more features designed with safety as the top priority.
          </p>
          <motion.a
            href="/demo"
            className="inline-flex items-center gap-2 px-8 py-4 bg-gold text-background font-semibold rounded-full hover:bg-gold-light transition-colors"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            See It In Action
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </motion.a>
        </motion.div>
      </div>
    </section>
  );
}
