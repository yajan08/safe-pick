"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Shield, Globe, Mail, MapPin, Phone } from "lucide-react";

const footerLinks = {
  product: [
    { label: "Home", href: "/" },
    { label: "About Us", href: "/about" },
    { label: "Contact Us", href: "/contact" },
    { label: "Demo", href: "/demo" },
  ],
  support: [
    { label: "Help Center", href: "#help" },
    { label: "Privacy Policy", href: "#privacy" },
    { label: "Terms of Service", href: "#terms" },
  ],
};

const socialLinks = [
  { icon: Globe, href: "#", label: "Website" },
  { icon: Mail, href: "#", label: "Email" },
];

export function Footer() {
  return (
    <footer className="py-16 px-6 bg-ebony border-t border-border">
      <div className="max-w-7xl mx-auto">
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
          {/* Brand column */}
          <div className="lg:col-span-2">
            <Link href="/" className="flex items-center gap-2 mb-4">
              <div className="w-10 h-10 rounded-xl bg-gold flex items-center justify-center">
                <Shield className="w-6 h-6 text-background" />
              </div>
              <span className="text-xl font-bold text-foreground">SafePick</span>
            </Link>
            <p className="text-muted max-w-sm mb-6 leading-relaxed">
              Ensuring the safety of every child&apos;s journey with real-time tracking and verified
              confirmations.
            </p>
            <div className="flex items-center gap-4">
              {socialLinks.map((social, index) => (
                <motion.a
                  key={index}
                  href={social.href}
                  className="w-10 h-10 rounded-full bg-ebony-light border border-border flex items-center justify-center hover:border-gold/50 transition-colors"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  aria-label={social.label}
                >
                  <social.icon className="w-4 h-4 text-muted" />
                </motion.a>
              ))}
            </div>
          </div>

          {/* Links columns */}
          <div>
            <h4 className="text-sm font-semibold text-foreground uppercase tracking-wider mb-4">
              Navigation
            </h4>
            <ul className="space-y-3">
              {footerLinks.product.map((link, index) => (
                <li key={index}>
                  <Link
                    href={link.href}
                    className="text-muted hover:text-gold transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-foreground uppercase tracking-wider mb-4">
              Support
            </h4>
            <ul className="space-y-3">
              {footerLinks.support.map((link, index) => (
                <li key={index}>
                  <Link
                    href={link.href}
                    className="text-muted hover:text-gold transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Contact info */}
        <div className="flex flex-col md:flex-row gap-6 md:gap-12 py-8 border-t border-border">
          <div className="flex items-center gap-3">
            <Mail className="w-4 h-4 text-gold" />
            <span className="text-muted text-sm">hello@safepick.in</span>
          </div>
          <div className="flex items-center gap-3">
            <Phone className="w-4 h-4 text-gold" />
            <span className="text-muted text-sm">+91 98765 43210</span>
          </div>
          <div className="flex items-center gap-3">
            <MapPin className="w-4 h-4 text-gold" />
            <span className="text-muted text-sm">Bangalore, India</span>
          </div>
        </div>

        {/* Copyright */}
        <div className="pt-8 border-t border-border flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-sm text-muted">
            &copy; {new Date().getFullYear()} SafePick. All rights reserved.
          </p>
          <p className="text-sm text-muted">
            Made with care for every child&apos;s safety
          </p>
        </div>
      </div>
    </footer>
  );
}
