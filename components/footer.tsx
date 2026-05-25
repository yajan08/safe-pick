"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Shield, Mail, MapPin, Phone, ArrowUpRight } from "lucide-react";

const footerLinks = {
  product: [
    { label: "Home", href: "/" },
    { label: "About Us", href: "/about" },
    { label: "Contact Us", href: "/contact" },
    { label: "Live Demo", href: "/demo" },
  ],
  legal: [
    { label: "Privacy Policy", href: "#privacy" },
    { label: "Terms of Service", href: "#terms" },
    { label: "Cookie Policy", href: "#cookies" },
  ],
};

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5 },
  },
};

export function Footer() {
  return (
    <footer className="py-16 px-6 bg-ebony border-t border-border transition-colors duration-300">
      <div className="max-w-7xl mx-auto">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12"
        >
          {/* Brand column */}
          <motion.div variants={itemVariants} className="lg:col-span-2">
            <Link href="/" className="flex items-center gap-3 mb-6 group">
              <motion.div
                className="w-12 h-12 rounded-xl bg-gold flex items-center justify-center"
                whileHover={{ rotate: 360 }}
                transition={{ duration: 0.5 }}
              >
                <Shield className="w-7 h-7 text-background" />
              </motion.div>
              <span className="text-2xl font-bold text-foreground group-hover:text-gold transition-colors">
                SafePick
              </span>
            </Link>
            <p className="text-muted max-w-sm mb-8 leading-relaxed">
              Ensuring the safety of every child&apos;s journey with real-time tracking, 
              verified confirmations, and complete peace of mind for parents and schools.
            </p>

            {/* Contact cards */}
            <div className="space-y-4">
              <motion.a
                href="mailto:hello@safepick.in"
                className="flex items-center gap-4 p-4 rounded-xl bg-card border border-border hover:border-gold/50 transition-all group"
                whileHover={{ x: 5 }}
              >
                <div className="w-10 h-10 rounded-lg bg-gold/10 flex items-center justify-center group-hover:bg-gold/20 transition-colors">
                  <Mail className="w-5 h-5 text-gold" />
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Email Us</p>
                  <p className="text-foreground font-medium">hello@safepick.in</p>
                </div>
                <ArrowUpRight className="w-4 h-4 text-muted ml-auto opacity-0 group-hover:opacity-100 transition-opacity" />
              </motion.a>

              <motion.a
                href="tel:+919876543210"
                className="flex items-center gap-4 p-4 rounded-xl bg-card border border-border hover:border-gold/50 transition-all group"
                whileHover={{ x: 5 }}
              >
                <div className="w-10 h-10 rounded-lg bg-gold/10 flex items-center justify-center group-hover:bg-gold/20 transition-colors">
                  <Phone className="w-5 h-5 text-gold" />
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Call Us</p>
                  <p className="text-foreground font-medium">+91 98765 43210</p>
                </div>
                <ArrowUpRight className="w-4 h-4 text-muted ml-auto opacity-0 group-hover:opacity-100 transition-opacity" />
              </motion.a>

              <div className="flex items-center gap-4 p-4 rounded-xl bg-card border border-border">
                <div className="w-10 h-10 rounded-lg bg-gold/10 flex items-center justify-center">
                  <MapPin className="w-5 h-5 text-gold" />
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Location</p>
                  <p className="text-foreground font-medium">Bangalore, India</p>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Navigation Links */}
          <motion.div variants={itemVariants}>
            <h4 className="text-sm font-semibold text-foreground uppercase tracking-wider mb-6">
              Navigation
            </h4>
            <ul className="space-y-4">
              {footerLinks.product.map((link, index) => (
                <motion.li 
                  key={index}
                  whileHover={{ x: 5 }}
                  transition={{ duration: 0.2 }}
                >
                  <Link
                    href={link.href}
                    className="text-muted hover:text-gold transition-colors flex items-center gap-2 group"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-gold/50 group-hover:bg-gold transition-colors" />
                    {link.label}
                  </Link>
                </motion.li>
              ))}
            </ul>
          </motion.div>

          {/* Legal Links */}
          <motion.div variants={itemVariants}>
            <h4 className="text-sm font-semibold text-foreground uppercase tracking-wider mb-6">
              Legal
            </h4>
            <ul className="space-y-4">
              {footerLinks.legal.map((link, index) => (
                <motion.li 
                  key={index}
                  whileHover={{ x: 5 }}
                  transition={{ duration: 0.2 }}
                >
                  <Link
                    href={link.href}
                    className="text-muted hover:text-gold transition-colors flex items-center gap-2 group"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-gold/50 group-hover:bg-gold transition-colors" />
                    {link.label}
                  </Link>
                </motion.li>
              ))}
            </ul>

            {/* Trust badges */}
            <div className="mt-8 space-y-3">
              <div className="flex items-center gap-2 text-xs text-muted">
                <Shield className="w-4 h-4 text-gold" />
                <span>GDPR Compliant</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted">
                <Shield className="w-4 h-4 text-gold" />
                <span>256-bit Encryption</span>
              </div>
            </div>
          </motion.div>
        </motion.div>

        {/* Bottom bar */}
        <motion.div 
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5 }}
          className="pt-8 border-t border-border flex flex-col md:flex-row justify-between items-center gap-4"
        >
          <p className="text-sm text-muted">
            &copy; {new Date().getFullYear()} SafePick. All rights reserved.
          </p>
          <p className="text-sm text-muted flex items-center gap-2">
            Made with <span className="text-gold">care</span> for every child&apos;s safety
          </p>
        </motion.div>
      </div>
    </footer>
  );
}
