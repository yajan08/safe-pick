"use client";

import { motion } from "framer-motion";
import { useState } from "react";
import {
  Users,
  Building2,
  Bell,
  MapPin,
  Shield,
  AlertTriangle,
  QrCode,
  Clock,
  CheckCircle2,
} from "lucide-react";

type Perspective = "parents" | "schools";

const perspectives = {
  parents: {
    title: "For Parents",
    subtitle: "Eliminating Uncertainty",
    description: "Know exactly where your child is at every moment with real-time notifications and verified confirmations.",
    features: [
      {
        icon: Bell,
        title: "Instant Notifications",
        description: "Get push alerts for every pickup and drop event",
      },
      {
        icon: MapPin,
        title: "Live Location",
        description: "Track the van in real-time on your phone",
      },
      {
        icon: QrCode,
        title: "QR Verification",
        description: "Secure pickup confirmation via QR scan",
      },
    ],
    timeline: [
      { time: "7:45 AM", event: "Van departed from depot", status: "complete" },
      { time: "7:52 AM", event: "Arriving at your stop in 3 mins", status: "complete" },
      { time: "7:55 AM", event: "Child boarded successfully", status: "complete" },
      { time: "8:15 AM", event: "Dropped at school gate", status: "active" },
    ],
  },
  schools: {
    title: "For Schools",
    subtitle: "Accountability & Security",
    description: "Complete oversight of your transport fleet with anti-cheat mechanisms and comprehensive logs.",
    features: [
      {
        icon: Shield,
        title: "Anti-Cheat System",
        description: "QR scans restricted to stop geofences only",
      },
      {
        icon: AlertTriangle,
        title: "Smart Alerts",
        description: "Automatic suspicious activity notifications",
      },
      {
        icon: Clock,
        title: "Full Audit Trail",
        description: "Complete logs of every trip and event",
      },
    ],
    timeline: [
      { time: "7:30 AM", event: "Driver authenticated via face scan", status: "complete" },
      { time: "7:45 AM", event: "Route optimized for 23 students", status: "complete" },
      { time: "8:00 AM", event: "Geofence alert: Van on route", status: "complete" },
      { time: "8:20 AM", event: "All students delivered safely", status: "active" },
    ],
  },
};

export function DualPerspective() {
  const [active, setActive] = useState<Perspective>("parents");
  const data = perspectives[active];

  return (
    <section className="py-24 px-6 relative overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-background via-ebony to-background" />

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="text-gold text-sm font-semibold tracking-wider uppercase">
            Built for Everyone
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mt-4 text-foreground">
            Two Perspectives, One Mission
          </h2>
          <p className="text-muted mt-4 max-w-2xl mx-auto text-balance">
            Whether you&apos;re a parent seeking peace of mind or a school ensuring accountability,
            SafePick delivers.
          </p>
        </motion.div>

        {/* Toggle */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="flex justify-center mb-12"
        >
          <div className="inline-flex p-1 rounded-full glass border border-gold/20">
            <button
              onClick={() => setActive("parents")}
              className={`flex items-center gap-2 px-6 py-3 rounded-full font-medium transition-all ${
                active === "parents"
                  ? "bg-gold text-background"
                  : "text-muted hover:text-foreground"
              }`}
            >
              <Users className="w-4 h-4" />
              For Parents
            </button>
            <button
              onClick={() => setActive("schools")}
              className={`flex items-center gap-2 px-6 py-3 rounded-full font-medium transition-all ${
                active === "schools"
                  ? "bg-gold text-background"
                  : "text-muted hover:text-foreground"
              }`}
            >
              <Building2 className="w-4 h-4" />
              For Schools
            </button>
          </div>
        </motion.div>

        {/* Content grid */}
        <div className="grid lg:grid-cols-2 gap-8">
          {/* Left - Features card */}
          <motion.div
            key={`features-${active}`}
            initial={{ opacity: 0, x: -30, rotateY: -5 }}
            animate={{ opacity: 1, x: 0, rotateY: 0 }}
            transition={{ duration: 0.5 }}
            className="group"
          >
            <motion.div
              className="h-full p-8 rounded-3xl glass border border-gold/20 relative overflow-hidden"
              whileHover={{
                rotateX: 2,
                rotateY: 2,
                boxShadow: "0 0 40px rgba(201, 146, 37, 0.2)",
              }}
              transition={{ duration: 0.3 }}
            >
              {/* Glow effect on hover */}
              <div className="absolute inset-0 bg-gradient-to-br from-gold/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

              <div className="relative z-10">
                <span className="text-gold text-sm font-semibold">{data.title}</span>
                <h3 className="text-2xl md:text-3xl font-bold mt-2 text-foreground">
                  {data.subtitle}
                </h3>
                <p className="text-muted mt-4 leading-relaxed">{data.description}</p>

                <div className="mt-8 space-y-6">
                  {data.features.map((feature, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.1 }}
                      className="flex items-start gap-4"
                    >
                      <div className="w-12 h-12 rounded-xl bg-gold/10 flex items-center justify-center flex-shrink-0">
                        <feature.icon className="w-6 h-6 text-gold" />
                      </div>
                      <div>
                        <h4 className="font-semibold text-foreground">{feature.title}</h4>
                        <p className="text-sm text-muted mt-1">{feature.description}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>
            </motion.div>
          </motion.div>

          {/* Right - Timeline card */}
          <motion.div
            key={`timeline-${active}`}
            initial={{ opacity: 0, x: 30, rotateY: 5 }}
            animate={{ opacity: 1, x: 0, rotateY: 0 }}
            transition={{ duration: 0.5 }}
            className="group"
          >
            <motion.div
              className="h-full p-8 rounded-3xl glass border border-gold/20 relative overflow-hidden"
              whileHover={{
                rotateX: -2,
                rotateY: -2,
                boxShadow: "0 0 40px rgba(201, 146, 37, 0.2)",
              }}
              transition={{ duration: 0.3 }}
            >
              <div className="absolute inset-0 bg-gradient-to-br from-gold/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

              <div className="relative z-10">
                <span className="text-gold text-sm font-semibold">Live Activity</span>
                <h3 className="text-2xl md:text-3xl font-bold mt-2 text-foreground">
                  Real-Time Updates
                </h3>
                <p className="text-muted mt-4">
                  See exactly what&apos;s happening, as it happens.
                </p>

                <div className="mt-8 space-y-4">
                  {data.timeline.map((item, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: index * 0.15 }}
                      className={`flex items-start gap-4 p-4 rounded-xl ${
                        item.status === "active"
                          ? "bg-gold/10 border border-gold/30"
                          : "bg-ebony-light"
                      }`}
                    >
                      <div
                        className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                          item.status === "active" ? "bg-gold" : "bg-gold/20"
                        }`}
                      >
                        <CheckCircle2
                          className={`w-4 h-4 ${
                            item.status === "active" ? "text-background" : "text-gold"
                          }`}
                        />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <p
                            className={`font-medium ${
                              item.status === "active" ? "text-gold" : "text-foreground"
                            }`}
                          >
                            {item.event}
                          </p>
                          <span className="text-xs text-muted">{item.time}</span>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
