      subroutine selci_prtcon(ifllog, norbs, ioconf, nintpo, nbitpi)
      dimension ioconf(nintpo),iocc(255)
c
      call selci_upkcon(norbs, iocc, ioconf, nintpo, nbitpi)
      call selci_wrtcon(ifllog, iocc, norbs)
c
      end
