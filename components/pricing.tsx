"use client";

import { motion } from "framer-motion";
import { Check, Sparkles, Building2, Users } from "lucide-react";

const plans = [
  {
    id: "monthly",
    name: "Monthly",
    price: "199",
    period: "/month",
    description: "Perfect for trying out SafePick",
    badge: null,
    features: [
      "Real-time GPS tracking",
      "Push notifications",
      "QR verification",
      "Basic support",
    ],
  },
  {
    id: "quarterly",
    name: "Quarterly",
    price: "549",
    period: "/quarter",
    description: "Save 8% with quarterly billing",
    badge: "Popular",
    features: [
      "Everything in Monthly",
      "Priority support",
      "Advanced analytics",
      "Custom alerts",
    ],
  },
  {
    id: "yearly",
    name: "Yearly",
    price: "1,999",
    period: "/year",
    description: "Best value - Save 17%",
    badge: "Best Value",
    features: [
      "Everything in Quarterly",
      "Dedicated support",
      "API access",
      "White-label options",
      "Unlimited users",
    ],
  },
];

export function Pricing() {
  return (
    <section className="py-24 px-6 relative overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-ebony via-background to-background" />

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="text-gold text-sm font-semibold tracking-wider uppercase">
            Simple Pricing
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mt-4 text-foreground">
            Choose Your Plan
          </h2>
          <p className="text-muted mt-4 max-w-2xl mx-auto text-balance">
            Transparent pricing with no hidden fees. Start free and upgrade when you&apos;re ready.
          </p>
        </motion.div>

        {/* Pricing cards */}
        <div className="grid md:grid-cols-3 gap-6 lg:gap-8 mb-16">
          {plans.map((plan, index) => (
            <motion.div
              key={plan.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              className={`relative p-8 rounded-3xl ${
                plan.badge === "Best Value"
                  ? "glass border-2 border-gold glow-gold"
                  : "bg-ebony-light border border-border"
              }`}
            >
              {/* Badge */}
              {plan.badge && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <div className="flex items-center gap-1 px-4 py-1 rounded-full bg-gold text-background text-xs font-semibold">
                    <Sparkles className="w-3 h-3" />
                    {plan.badge}
                  </div>
                </div>
              )}

              <div className="text-center mb-6">
                <h3 className="text-xl font-semibold text-foreground">{plan.name}</h3>
                <p className="text-sm text-muted mt-1">{plan.description}</p>
              </div>

              <div className="text-center mb-8">
                <span className="text-4xl md:text-5xl font-bold text-foreground">
                  <span className="text-gold">&#8377;</span>
                  {plan.price}
                </span>
                <span className="text-muted">{plan.period}</span>
              </div>

              <ul className="space-y-4 mb-8">
                {plan.features.map((feature, featureIndex) => (
                  <li key={featureIndex} className="flex items-center gap-3">
                    <div className="w-5 h-5 rounded-full bg-gold/20 flex items-center justify-center flex-shrink-0">
                      <Check className="w-3 h-3 text-gold" />
                    </div>
                    <span className="text-sm text-foreground">{feature}</span>
                  </li>
                ))}
              </ul>

              <motion.button
                className={`w-full py-4 rounded-xl font-semibold transition-all ${
                  plan.badge === "Best Value"
                    ? "bg-gold text-background hover:bg-gold-light"
                    : "bg-ebony border border-gold/50 text-gold hover:bg-gold/10"
                }`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Get Started
              </motion.button>
            </motion.div>
          ))}
        </div>

        {/* CTA buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="flex flex-col sm:flex-row gap-4 justify-center"
        >
          <motion.button
            className="group relative px-8 py-4 rounded-full bg-gold text-background font-semibold overflow-hidden flex items-center justify-center gap-2"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <Building2 className="w-5 h-5" />
            <span className="relative z-10">Onboard Your School</span>
            <motion.div
              className="absolute inset-0 bg-gradient-to-r from-gold-light to-gold"
              initial={{ x: "-100%" }}
              whileHover={{ x: 0 }}
              transition={{ duration: 0.3 }}
            />
          </motion.button>
          <motion.button
            className="px-8 py-4 rounded-full border border-gold/50 text-gold font-semibold hover:bg-gold/10 transition-colors flex items-center justify-center gap-2"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <Users className="w-5 h-5" />
            Get SafePick for Parents
          </motion.button>
        </motion.div>
      </div>
    </section>
  );
}
