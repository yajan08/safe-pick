"use client";

import { motion } from "framer-motion";
import { useState } from "react";
import {
  CreditCard,
  AlertTriangle,
  WifiOff,
  CheckCircle2,
  Clock,
  Bell,
  Shield,
  type LucideIcon,
} from "lucide-react";

interface EdgeCase {
  id: string;
  title: string;
  subtitle: string;
  icon: LucideIcon;
  description: string;
  demo:
    | { type: "verification"; stages: { label: string; status: string }[] }
    | { type: "alert"; message: string; priority: string }
    | { type: "sync"; stages: string[] };
}

const edgeCases: EdgeCase[] = [
  {
    id: "forgot-qr",
    title: "Forgot QR Card",
    subtitle: "Seamless Manual Override",
    icon: CreditCard,
    description:
      "When a student forgets their QR card, the system enables a secure manual verification process with parent confirmation.",
    demo: {
      type: "verification",
      stages: [
        { label: "QR Scan Failed", status: "warning" },
        { label: "Manual Override Initiated", status: "pending" },
        { label: "Parent Notified", status: "active" },
        { label: "Verification Complete", status: "success" },
      ],
    },
  },
  {
    id: "bypass",
    title: "Van Bypassed Stop",
    subtitle: "Instant Alert System",
    icon: AlertTriangle,
    description:
      "If a van misses a scheduled stop, the system immediately triggers alerts to parents and administrators.",
    demo: {
      type: "alert",
      message: "ALERT: Van #12 bypassed Sector 15 stop",
      priority: "high",
    },
  },
  {
    id: "offline",
    title: "Offline Mode",
    subtitle: "Continuous Tracking",
    icon: WifiOff,
    description:
      "Network drops don't break tracking. Data syncs automatically when connectivity is restored.",
    demo: {
      type: "sync",
      stages: ["Offline detected", "Local caching active", "Connection restored", "Data synced"],
    },
  },
];

function VerificationDemo({ stages }: { stages: { label: string; status: string }[] }) {
  return (
    <div className="space-y-3">
      {stages.map((stage, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: index * 0.2 }}
          className={`flex items-center gap-3 p-3 rounded-lg ${
            stage.status === "warning"
              ? "bg-amber-500/10 border border-amber-500/30"
              : stage.status === "pending"
                ? "bg-gold/10 border border-gold/30"
                : stage.status === "active"
                  ? "bg-blue-500/10 border border-blue-500/30 animate-pulse"
                  : "bg-emerald-500/10 border border-emerald-500/30"
          }`}
        >
          <div
            className={`w-6 h-6 rounded-full flex items-center justify-center ${
              stage.status === "warning"
                ? "bg-amber-500"
                : stage.status === "pending"
                  ? "bg-gold"
                  : stage.status === "active"
                    ? "bg-blue-500"
                    : "bg-emerald-500"
            }`}
          >
            {stage.status === "success" ? (
              <CheckCircle2 className="w-4 h-4 text-background" />
            ) : stage.status === "warning" ? (
              <AlertTriangle className="w-4 h-4 text-background" />
            ) : (
              <Clock className="w-4 h-4 text-background" />
            )}
          </div>
          <span
            className={`text-sm font-medium ${
              stage.status === "warning"
                ? "text-amber-400"
                : stage.status === "pending"
                  ? "text-gold"
                  : stage.status === "active"
                    ? "text-blue-400"
                    : "text-emerald-400"
            }`}
          >
            {stage.label}
          </span>
        </motion.div>
      ))}
    </div>
  );
}

function AlertDemo({ message, priority }: { message: string; priority: string }) {
  return (
    <motion.div
      initial={{ scale: 0.9, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      className="relative"
    >
      <motion.div
        className={`p-4 rounded-xl border-2 ${
          priority === "high"
            ? "bg-red-500/10 border-red-500/50"
            : "bg-amber-500/10 border-amber-500/50"
        }`}
        animate={{
          boxShadow: [
            "0 0 0 rgba(239, 68, 68, 0)",
            "0 0 30px rgba(239, 68, 68, 0.3)",
            "0 0 0 rgba(239, 68, 68, 0)",
          ],
        }}
        transition={{ duration: 1.5, repeat: Infinity }}
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center">
            <Bell className="w-5 h-5 text-red-400" />
          </div>
          <div>
            <p className="text-xs text-red-400 font-semibold uppercase tracking-wide">
              Priority Alert
            </p>
            <p className="text-sm text-foreground font-medium mt-1">{message}</p>
          </div>
        </div>
        <div className="mt-3 flex gap-2">
          <button className="px-3 py-1.5 text-xs font-medium rounded-lg bg-red-500 text-white">
            Contact Driver
          </button>
          <button className="px-3 py-1.5 text-xs font-medium rounded-lg bg-ebony-light text-foreground border border-border">
            View Details
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}

function SyncDemo({ stages }: { stages: string[] }) {
  return (
    <div className="space-y-3">
      {stages.map((stage, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, width: 0 }}
          animate={{ opacity: 1, width: "100%" }}
          transition={{ delay: index * 0.3, duration: 0.5 }}
          className="flex items-center gap-3"
        >
          <motion.div
            className={`w-3 h-3 rounded-full ${
              index === 0
                ? "bg-amber-500"
                : index === stages.length - 1
                  ? "bg-emerald-500"
                  : "bg-gold"
            }`}
            animate={index === stages.length - 1 ? { scale: [1, 1.2, 1] } : {}}
            transition={{ duration: 0.5, repeat: Infinity }}
          />
          <div className="flex-1 h-1 bg-ebony-light rounded-full overflow-hidden">
            <motion.div
              className={`h-full ${
                index === 0
                  ? "bg-amber-500"
                  : index === stages.length - 1
                    ? "bg-emerald-500"
                    : "bg-gold"
              }`}
              initial={{ width: 0 }}
              animate={{ width: "100%" }}
              transition={{ delay: index * 0.3 + 0.2, duration: 0.4 }}
            />
          </div>
          <span className="text-xs text-muted">{stage}</span>
        </motion.div>
      ))}
    </div>
  );
}

export function EdgeCases() {
  const [activeCase, setActiveCase] = useState(0);
  const currentCase = edgeCases[activeCase];

  return (
    <section className="py-24 px-6 relative overflow-hidden bg-ebony">
      {/* Background pattern */}
      <div className="absolute inset-0 map-grid opacity-30" />

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="text-gold text-sm font-semibold tracking-wider uppercase">
            Edge Case Handling
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mt-4 text-foreground">
            Built for the Real World
          </h2>
          <p className="text-muted mt-4 max-w-2xl mx-auto text-balance">
            Life is unpredictable. SafePick handles every scenario gracefully, ensuring
            uninterrupted safety.
          </p>
        </motion.div>

        {/* Cases grid */}
        <div className="grid lg:grid-cols-3 gap-6 mb-12">
          {edgeCases.map((edgeCase, index) => (
            <motion.button
              key={edgeCase.id}
              onClick={() => setActiveCase(index)}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              className={`p-6 rounded-2xl text-left transition-all ${
                activeCase === index
                  ? "glass border-2 border-gold glow-gold"
                  : "bg-ebony-light border border-border hover:border-gold/50"
              }`}
            >
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center mb-4 ${
                  activeCase === index ? "bg-gold" : "bg-gold/10"
                }`}
              >
                <edgeCase.icon
                  className={`w-6 h-6 ${
                    activeCase === index ? "text-background" : "text-gold"
                  }`}
                />
              </div>
              <h3
                className={`font-semibold ${
                  activeCase === index ? "text-gold" : "text-foreground"
                }`}
              >
                {edgeCase.title}
              </h3>
              <p className="text-sm text-muted mt-1">{edgeCase.subtitle}</p>
            </motion.button>
          ))}
        </div>

        {/* Active case demo */}
        <motion.div
          key={currentCase.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          className="grid lg:grid-cols-2 gap-8"
        >
          {/* Description */}
          <div className="flex flex-col justify-center">
            <div className="flex items-center gap-3 mb-4">
              <Shield className="w-5 h-5 text-gold" />
              <span className="text-sm text-gold font-medium">How SafePick Handles It</span>
            </div>
            <h3 className="text-2xl md:text-3xl font-bold text-foreground mb-4">
              {currentCase.title}
            </h3>
            <p className="text-muted leading-relaxed">{currentCase.description}</p>
          </div>

          {/* Demo visualization */}
          <div className="p-6 rounded-2xl glass border border-gold/20">
            <p className="text-xs text-muted uppercase tracking-wide mb-4">Live Demo</p>
            {currentCase.demo.type === "verification" && (
              <VerificationDemo stages={currentCase.demo.stages} />
            )}
            {currentCase.demo.type === "alert" && (
              <AlertDemo
                message={currentCase.demo.message}
                priority={currentCase.demo.priority}
              />
            )}
            {currentCase.demo.type === "sync" && (
              <SyncDemo stages={currentCase.demo.stages} />
            )}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
