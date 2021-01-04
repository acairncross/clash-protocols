{-|
Defines WriteResponse channel of full AXI4 protocol with port names corresponding
to the AXI4 specification.
-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE UndecidableInstances #-}

{-# OPTIONS_GHC -Wno-missing-fields #-}

module Protocols.Axi4.Raw.Full.WriteResponse
  ( M2S_WriteResponse(..)
  , S2M_WriteResponse(..)
  , Axi4WriteResponse
  ) where

-- base
import Data.Coerce (coerce)
import Data.Kind (Type)
import GHC.Generics (Generic)
import Data.Proxy

-- clash-prelude
import qualified Clash.Prelude as C
import Clash.Prelude ((:::))

-- me
import Protocols.Axi4.Raw.Common
import Protocols.Internal
import Protocols.DfLike (DfLike)
import qualified Protocols.DfLike as DfLike

-- | AXI4 Read Data channel protocol
data Axi4WriteResponse
  (dom :: C.Domain)
  (kr :: KeepResponse)
  (iw :: IdWidth)
  (userType :: Type)

instance Protocol (Axi4WriteResponse dom kr iw userType) where
  type Fwd (Axi4WriteResponse dom kr iw userType) =
    C.Signal dom (S2M_WriteResponse kr iw userType)
  type Bwd (Axi4WriteResponse dom kr iw userType) =
    C.Signal dom M2S_WriteResponse

instance Backpressure (Axi4WriteResponse dom kr iw userType) where
  boolsToBwd _ = C.fromList_lazy . coerce

instance DfLike dom (Axi4WriteResponse dom kr iw) userType where
  type Data (Axi4WriteResponse dom kr iw) userType =
    S2M_WriteResponse kr iw userType

  type Payload userType = userType

  type Ack (Axi4WriteResponse dom kr iw) userType =
    M2S_WriteResponse

  getPayload _ (S2M_WriteResponse{_bvalid=True, _buser}) = Just _buser
  getPayload _ _ = Nothing
  {-# INLINE getPayload #-}

  setPayload _ _ dat (Just b) = dat{_bvalid=True, _buser=b}
  setPayload _ dfB _ Nothing = DfLike.noData dfB
  {-# INLINE setPayload #-}

  noData _ = S2M_WriteResponse{_bvalid=False}
  {-# INLINE noData #-}

  boolToAck _ = coerce
  {-# INLINE boolToAck #-}

  ackToBool _ = coerce
  {-# INLINE ackToBool #-}

instance (C.KnownDomain dom, C.NFDataX userType, C.ShowX userType, Show userType) =>
  Simulate (Axi4WriteResponse dom kr iw userType) where

  type SimulateType (Axi4WriteResponse dom kr iw userType) =
    [S2M_WriteResponse kr iw userType]

  type ExpectType (Axi4WriteResponse dom kr iw userType) =
    [S2M_WriteResponse kr iw userType]

  type SimulateChannels (Axi4WriteResponse dom kr iw userType) = 1

  toSimulateType _ = id
  fromSimulateType _ = id

  driveC = DfLike.drive Proxy
  sampleC = DfLike.sample Proxy
  stallC conf (C.head -> (stallAck, stalls)) =
    DfLike.stall Proxy conf stallAck stalls

-- | See Table A2-4 "Write response channel signals"
data S2M_WriteResponse
  (kr :: KeepResponse)
  (iw :: IdWidth)
  (userType :: Type) =
  S2M_WriteResponse
    { -- | Response ID
      _bid :: "BID" ::: C.BitVector (Width iw)

      -- | Write response
    , _bresp :: "BRESP" ::: ResponseType kr

      -- | Write response valid
    , _bvalid :: "BVALID" ::: Bool

      -- | User data
    , _buser :: "BUSER" ::: userType
    }
  deriving (Generic)

-- | See Table A2-4 "Write response channel signals"
newtype M2S_WriteResponse = M2S_WriteResponse
  { _bready :: "BREADY" ::: Bool }
  deriving (Show, Generic, C.NFDataX)

deriving instance
  ( C.NFDataX userType
  , C.NFDataX (ResponseType kr) ) =>
  C.NFDataX (S2M_WriteResponse kr iw userType)

deriving instance
  ( Show userType
  , Show (ResponseType kr)
  , C.KnownNat (Width iw) ) =>
  Show (S2M_WriteResponse kr iw userType)