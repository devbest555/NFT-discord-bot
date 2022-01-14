const { MessageEmbed } = require('discord.js');

/**
 * Custom Command class
 */
class Command {

  /**
   * Create new command
   * @param {Client} client 
   * @param {Object} options 
   */
  constructor(client, options) {

    // Validate all options passed
    this.constructor.validateOptions(client, options);

    /**
     * The client
     * @type {Client}
     */
    this.client = client;

    /**
     * Name of the command
     * @type {string}
     */
    this.name = options.name;

    /**
     * Aliases of the command
     * @type {Array<string>}
     */
    this.aliases = options.aliases || null;

    /**
     * The arguments for the command
     * @type {string}
     */
    this.usage = options.usage || options.name;

    /**
     * The description for the command
     * @type {string}
     */
    this.description = options.description || '';

    /**
     * The type of command
     * @type {string}
     */
    this.type = options.type || client.types.MISC;

    /**
     * The client permissions needed
     * @type {Array<string>}
     */
    this.clientPermissions = options.clientPermissions || ['SEND_MESSAGES', 'EMBED_LINKS'];

    /**
     * The user permissions needed
     * @type {Array<string>}
     */
    this.userPermissions = options.userPermissions || null;

    /**
     * Examples of how the command is used
     * @type {Array<string>}
     */
    this.examples = options.examples || null;
    
    /**
     * If command can only be used by owner
     * @type {boolean}
     */
    this.ownerOnly = options.ownerOnly || false;

    /**
     * If command is enabled
     * @type {boolean}
     */
    this.disabled = options.disabled || false;

    /**
     * Array of error types
     * @type {Array<string>}
     */
    this.errorTypes = ['Invalid Argument', 'Command Failure'];
  }
  
   /**
   * Runs the command
   * @param {Message} message 
   * @param {string[]} args 
   */
  // eslint-disable-next-line no-unused-vars
  run(message, args) {
    throw new Error(`The ${this.name} command has no run() method`);
  }
  /**
   * Gets member from mention
   * @param {Message} message 
   * @param {string} mention 
   */
   getMemberFromMention(message, mention) {
    if (!mention) return;
    const matches = mention.match(/^<@!?(\d+)>$/);
    if (!matches) return;
    const id = matches[1];
    return message.guild.members.cache.get(id);
  }

  /**
   * Gets role from mention
   * @param {Message} message 
   * @param {string} mention 
   */
   getRoleFromMention(message, mention) {
    if (!mention) return;
    const matches = mention.match(/^<@&(\d+)>$/);
    if (!matches) return;
    const id = matches[1];
    return message.guild.roles.cache.get(id);
  }

module.exports = Command;