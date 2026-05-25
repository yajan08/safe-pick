"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { useState } from "react";
import { Shield, Menu, X, Sun, Moon } from "lucide-react";
import { useTheme } from "./theme-provider";

const navLinks = [
  { label: "Home", href: "/" },
  { label: "About Us", href: "/about" },
  { label: "Contact Us", href: "/contact" },
];

export function Navbar() {
  const [isOpen, setIsOpen] = useState(false);
  const { theme, toggleTheme } = useTheme();

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.5 }}
      className="fixed top-0 left-0 right-0 z-50 px-6 py-4"
    >
      <div className="max-w-7xl mx-auto">
        <div className="flex items-center justify-between px-6 py-3 rounded-2xl glass border border-gold/20 transition-colors duration-300">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <motion.div
              className="w-10 h-10 rounded-xl bg-gold flex items-center justify-center transition-colors duration-300"
              whileHover={{ rotate: 360 }}
              transition={{ duration: 0.5 }}
            >
              <Shield className="w-6 h-6 text-background" />
            </motion.div>
            <span className="text-xl font-bold text-foreground">SafePick</span>
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((link, index) => (
              <Link
                key={index}
                href={link.href}
                className="text-sm text-muted hover:text-gold transition-colors"
              >
                {link.label}
              </Link>
            ))}
          </div>

          {/* Theme Toggle */}
          <div className="hidden md:flex items-center">
            <motion.button
              onClick={toggleTheme}
              className="p-3 rounded-full glass border border-gold/20 hover:border-gold/50 transition-colors"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              aria-label="Toggle theme"
            >
              {theme === "dark" ? (
                <Sun className="w-5 h-5 text-gold" />
              ) : (
                <Moon className="w-5 h-5 text-gold" />
              )}
            </motion.button>
          </div>

          {/* Mobile menu button */}
          <div className="flex md:hidden items-center gap-3">
            <button
              onClick={toggleTheme}
              className="p-2 rounded-full glass border border-gold/20"
              aria-label="Toggle theme"
            >
              {theme === "dark" ? (
                <Sun className="w-5 h-5 text-gold" />
              ) : (
                <Moon className="w-5 h-5 text-gold" />
              )}
            </button>
            <button
              onClick={() => setIsOpen(!isOpen)}
              className="p-2 text-foreground"
              aria-label="Toggle menu"
            >
              {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="md:hidden mt-4 p-6 rounded-2xl glass border border-gold/20"
          >
            <div className="flex flex-col gap-4">
              {navLinks.map((link, index) => (
                <Link
                  key={index}
                  href={link.href}
                  onClick={() => setIsOpen(false)}
                  className="text-foreground hover:text-gold transition-colors py-2"
                >
                  {link.label}
                </Link>
              ))}
            </div>
          </motion.div>
        )}
      </div>
    </motion.nav>
  );
}
